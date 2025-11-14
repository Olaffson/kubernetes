Param(
    [string]$RepoRoot = ".",
    [string]$Namespace = "okotwica",
    [string]$MysqlServiceName = "mysql-svc",
    [switch]$VerboseLog
)

function Write-Info($msg) {
    if ($VerboseLog) { Write-Host "[INFO] $msg" }
    else { Write-Host $msg }
}

function Assert-Command($cmd) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "Command '$cmd' not found. Please install it and retry."
    }
}

function Kube-WaitNsGone($ns, $timeoutSec=180) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
        $exists = kubectl get ns $ns --no-headers 2>$null
        if (-not $?) { return $true }
        Start-Sleep -Seconds 3
    }
    return $false
}

function Apply-IfExists($path) {
    if (Test-Path $path) {
        Write-Info "kubectl apply -f $path"
        kubectl apply -f $path
        if (-not $?) { throw "Failed: kubectl apply -f $path" }
    } else {
        Write-Host "Warning: file not found: $path"
    }
}

# ----- Checks -----
Assert-Command kubectl
Write-Info "kubectl current-context:"
kubectl config current-context

# ----- 1) Delete namespace -----
Write-Info "Deleting namespace '$Namespace' if it exists ..."
kubectl delete namespace $Namespace --ignore-not-found
$gone = Kube-WaitNsGone -ns $Namespace -timeoutSec 240
if (-not $gone) {
    throw "Namespace '$Namespace' was not deleted in time."
}

# ----- 2) Recreate namespace -----
$nsFile = Join-Path $RepoRoot "k8s/namespace.yaml"
if (Test-Path $nsFile) {
    Apply-IfExists $nsFile
} else {
    Write-Info "Creating namespace '$Namespace' inline (k8s/namespace.yaml not found)."
@"
apiVersion: v1
kind: Namespace
metadata:
  name: $Namespace
"@ | kubectl apply -f -
}

# ----- 3) Secrets -----
Apply-IfExists (Join-Path $RepoRoot "k8s/secrets.yaml")

# ----- 4) MySQL: PVC / Deployment / Service -----
$mysqlBase = Join-Path $RepoRoot "k8s"
Apply-IfExists (Join-Path $mysqlBase "mysql_pvc.yaml")
Apply-IfExists (Join-Path $mysqlBase "mysql_deployment.yaml")
Apply-IfExists (Join-Path $mysqlBase "mysql_service.yaml")

# Ensure alias Service with the name expected by API (e.g., mysql-svc)
Write-Info "Ensuring alias Service '$MysqlServiceName' -> selector app=mysql."
@"
apiVersion: v1
kind: Service
metadata:
  name: $MysqlServiceName
  namespace: $Namespace
spec:
  selector:
    app: mysql
  ports:
    - port: 3306
      targetPort: 3306
  type: ClusterIP
"@ | kubectl apply -f -

# ----- 5) API: Deployment & Service -----
$apiBase = Join-Path $RepoRoot "k8s"
Apply-IfExists (Join-Path $apiBase "api_deployment.yaml")
Apply-IfExists (Join-Path $apiBase "api_service.yaml")

# ----- 6) Ingress -----
Apply-IfExists (Join-Path $RepoRoot "k8s/ingress.yaml")

# ----- 7) Wait for deployments -----
Write-Info "Waiting for deployments in namespace '$Namespace' to become Available ..."
kubectl wait --namespace $Namespace --for=condition=available deploy --all --timeout=180s 2>$null | Out-Null

# ----- 8) Verify resources -----
Write-Host ""
Write-Host "Verification des ressources Kubernetes pour le namespace '$Namespace'..."

$pods = kubectl get pods -n $Namespace --no-headers 2>$null
if ($pods) {
    Write-Host ""
    Write-Host "Pods detectes :"
    kubectl get pods -n $Namespace -o wide
} else {
    Write-Host ""
    Write-Host "Aucun pod trouve dans le namespace '$Namespace'."
}

$svc = kubectl get svc -n $Namespace --no-headers 2>$null
if ($svc) {
    Write-Host ""
    Write-Host "Services detectes :"
    kubectl get svc -n $Namespace -o wide
} else {
    Write-Host ""
    Write-Host "Aucun service trouve dans le namespace '$Namespace'."
}

$ing = kubectl get ingress -n $Namespace --no-headers 2>$null
if ($ing) {
    Write-Host ""
    Write-Host "Ingress detecte :"
    kubectl get ingress -n $Namespace -o wide
} else {
    Write-Host ""
    Write-Host "Aucun ingress trouve dans le namespace '$Namespace'."
}

Write-Host ""
Write-Host "Verification terminee."
Write-Host "Si tout est present, testez l'API avec :"
Write-Host "  curl http://4.251.145.205/$Namespace/health"
Write-Host "  curl http://4.251.145.205/$Namespace/clients"
