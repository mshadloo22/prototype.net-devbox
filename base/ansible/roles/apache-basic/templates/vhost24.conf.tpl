# Default Apache virtualhost template

<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName {{ apache.servername }}
    ServerAlias {{ apache.host }}
    DocumentRoot {{ apache.frontend_path }}

    # proxy pass all other traffics to DEV server, allow sending traffic to other applications
    SSLProxyEngine on
    ProxyPass "{{ apache.url_path }}/" !
    ProxyPass "/" "https://{{ apache.servername }}/"
    ProxyPassReverse "/" "https://{{ apache.servername }}/"

    Alias {{ apache.url_path }}/api/ {{ apache.api_path }}/
    <Directory {{ apache.api_path }}>
        Options -Indexes +FollowSymLinks +MultiViews +Includes

        AllowOverride None
        Require all granted

        RMode config
        RUidGid vagrant vagrant

        RewriteEngine On

        RewriteCond %{REQUEST_URI}::$1 ^(/.+)/(.*)::\2$
        RewriteRule ^(.*) - [E=BASE:%1]

        RewriteCond %{HTTP:Authorization} .
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

        RewriteCond %{ENV:REDIRECT_STATUS} ^$
        RewriteRule ^app\.php(/(.*)|$) %{ENV:BASE}/$2 [R=301,L]

        RewriteCond %{REQUEST_FILENAME} -f
        RewriteRule .? - [L]

        RewriteRule .? %{ENV:BASE}/app_dev.php [L]
    </Directory>

    Alias {{ apache.url_path }}/admin/ {{ apache.admin_path }}/
    <Directory {{ apache.admin_path }}>
        Options -Indexes +FollowSymLinks +MultiViews +Includes

        AllowOverride None
        Require all granted

        RMode config
        RUidGid vagrant vagrant
    </Directory>

    Alias {{ apache.url_path }}/ {{ apache.frontend_path }}/
    <Directory {{ apache.frontend_path }}>
        Options -Indexes +FollowSymLinks +MultiViews +Includes

        AllowOverride None
        Require all granted

        RMode config
        RUidGid vagrant vagrant
    </Directory>

</VirtualHost>
