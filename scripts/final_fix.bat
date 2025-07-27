@echo off
echo ========================================
echo Crys Garage - Final Fix
echo ========================================
echo Server: 209.74.80.162 (crysgarage.studio)
echo.

echo Step 1: Building frontend locally (we know this works)...
cd crysgarage-frontend
call npm run build
if %errorlevel% neq 0 (
    echo ❌ Frontend build failed locally
    pause
    exit /b 1
)
echo ✅ Frontend built successfully locally
cd ..
echo.

echo Step 2: Creating proper Nginx config...
(
echo server {
echo     listen 80;
echo     server_name crysgarage.studio www.crysgarage.studio;
echo.    
echo     root /var/www/crysgarage-frontend;
echo     index index.html;
echo.    
echo     # Handle React routing
echo     location / {
echo         try_files $uri $uri/ /index.html;
echo     }
echo.    
echo     # API proxy
echo     location /api/ {
echo         proxy_pass http://localhost:8000/;
echo         proxy_set_header Host $host;
echo         proxy_set_header X-Real-IP $remote_addr;
echo         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
echo         proxy_set_header X-Forwarded-Proto $scheme;
echo     }
echo.    
echo     # Audio processing proxy
echo     location /audio/ {
echo         proxy_pass http://localhost:4567/;
echo         proxy_set_header Host $host;
echo         proxy_set_header X-Real-IP $remote_addr;
echo         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
echo         proxy_set_header X-Forwarded-Proto $scheme;
echo     }
echo.    
echo     # Static files
echo     location ~* \.(js^|css^|png^|jpg^|jpeg^|gif^|ico^|svg^)$ {
echo         expires 1y;
echo         add_header Cache-Control "public, immutable";
echo     }
echo }
) > nginx_config.conf
echo ✅ Nginx config created
echo.

echo Step 3: Creating directory and uploading frontend...
ssh root@209.74.80.162 "mkdir -p /var/www/crysgarage-frontend"
scp -r crysgarage-frontend\dist\* root@209.74.80.162:/var/www/crysgarage-frontend/
echo ✅ Frontend files uploaded
echo.

echo Step 4: Setting permissions...
ssh root@209.74.80.162 "chown -R nginx:nginx /var/www/crysgarage-frontend && chmod -R 755 /var/www/crysgarage-frontend"
echo ✅ Permissions set
echo.

echo Step 5: Uploading and applying Nginx config...
scp nginx_config.conf root@209.74.80.162:/etc/nginx/conf.d/crysgarage.studio.conf
ssh root@209.74.80.162 "nginx -t && systemctl restart nginx"
echo ✅ Nginx configured and restarted
echo.

echo Step 6: Testing the website...
ssh root@209.74.80.162 "curl -I http://localhost"
echo.

echo Step 7: Verifying files are in place...
ssh root@209.74.80.162 "ls -la /var/www/crysgarage-frontend/"
echo.

echo Step 8: Checking Nginx status...
ssh root@209.74.80.162 "systemctl status nginx --no-pager"
echo.

echo ========================================
echo Final fix complete!
echo ========================================
echo.
echo 🌐 Visit: http://crysgarage.studio
echo.
echo If you still see issues, run: .\fix_500_error.bat
echo.
pause 