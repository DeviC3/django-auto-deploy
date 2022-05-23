# Fast build Django on Linux

## Description

You can have one or more reason's to not to use Docker. I had one so I've created script to fast build Django app on Linux machines.
Default database is postgres if You need for other engine, write to me I will upload new script in this repository.
Django works on Nginx with Gunicorn and as systemd service.

## How to use

1. Download script on Your machine:

```
wget https://raw.githubusercontent.com/DeviC3/django-auto-deploy/master/djangobuild.sh
```

or

```
curl https://raw.githubusercontent.com/DeviC3/django-auto-deploy/master/djangobuild.sh -o djangobuild.sh
```

2. Customize variables:

- **dbuser** - database username
- **dbname** - database name
- **dbpassword** - database password
- **venv** - virtualenv name adn projectname
- **myprojectdir** - base project directory
- **domainName** - domain name or IP address (default id IP to fill ALLOWED_HOSTS variable)

3. Use it ```bash djangodeploy.sh```
