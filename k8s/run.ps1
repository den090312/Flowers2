Write-Host "=== Установка Kubernetes Gateway API ===" -ForegroundColor Green

# 1. Устанавливаем Gateway API CRDs
Write-Host "Устанавливаем Gateway API CRDs..." -ForegroundColor Yellow
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# 2. Устанавливаем Envoy Gateway
Write-Host "Устанавливаем Envoy Gateway..." -ForegroundColor Yellow
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.0.0/install.yaml
kubectl apply -f patch-service.yaml

# 3. Запускаем локальный Docker registry
Write-Host "Запускаем локальный Docker registry..." -ForegroundColor Yellow
docker run -d -p 5000:5000 --name registry registry:2

Write-Host "=== Установка завершена ===" -ForegroundColor Green
Write-Host "Проверяем установку: kubectl get pods -n envoy-gateway-system" -ForegroundColor Cyan

Write-Host "`nBuilding Billing..." -ForegroundColor Yellow
cd C:\Users\User\source\repos\Flowers\Billing\Billing
docker build -t billing:latest .
cd ..\..

Write-Host "`nBuilding Delivery..." -ForegroundColor Yellow  
cd C:\Users\User\source\repos\Flowers\Delivery\Delivery
docker build -t delivery:latest .
cd ..\..

Write-Host "`nBuilding Order..." -ForegroundColor Yellow
cd C:\Users\User\source\repos\Flowers\Order\Order
docker build -t order:latest .
cd ..\..

Write-Host "`nBuilding Product..." -ForegroundColor Yellow
cd C:\Users\User\source\repos\Flowers\Product\Product
docker build -t product:latest .
cd ..\..

Write-Host "`nBuilding User..." -ForegroundColor Yellow
cd C:\Users\User\source\repos\Flowers\User\User
docker build -t user:latest .
cd ..\..

Write-Host "`nBuilding Warehouse..." -ForegroundColor Yellow
cd C:\Users\User\source\repos\Flowers\Warehouse\Warehouse
docker build -t warehouse:latest .
cd ..\..

$services = @("billing", "delivery", "order", "product", "user", "warehouse")

foreach ($service in $services) {
    Write-Host "Обрабатываем $service..." -ForegroundColor Cyan
    docker tag ${service}:latest localhost:5000/${service}:latest
    docker push localhost:5000/${service}:latest
    Write-Host "$service успешно загружен в registry" -ForegroundColor Green
}

Write-Host "=== Все образы загружены в локальный registry ===" -ForegroundColor Green

Write-Host "=== Деплой приложения Flowers в Kubernetes ===" -ForegroundColor Green

# Сначала создаем GatewayClass
Write-Host "Создаем GatewayClass..." -ForegroundColor Yellow
kubectl apply -f gatewayclass.yaml

# Ждем немного
Start-Sleep -Seconds 5

# Применяем манифесты
Write-Host "Применяем Gateway..." -ForegroundColor Yellow
kubectl apply -f gateway.yaml

Write-Host "Применяем Deployment и Service..." -ForegroundColor Yellow
kubectl apply -f deployments.yaml

# Ждем запуска подов
Write-Host "Ожидаем запуск подов..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Показываем статус
Write-Host "=== Статус развертывания ===" -ForegroundColor Green
kubectl get pods
kubectl get services
kubectl get gatewayclass
kubectl get gateway

Write-Host "`n=== Проверка Gateway ===" -ForegroundColor Cyan
kubectl get gateway -o wide

Write-Host "`nДля получения внешнего IP выполни:" -ForegroundColor Yellow
Write-Host "kubectl get service -n envoy-gateway-system" -ForegroundColor White