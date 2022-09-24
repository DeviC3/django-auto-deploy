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

or autoinstall from Github

```
bash -c "$(curl https://raw.githubusercontent.com/DeviC3/django-auto-deploy/master/djangobuild.sh )" -s dbusername dbname dbpassword project_name
```


2. Customize variables:

- **dbuser** - database username
- **dbname** - database name
- **dbpassword** - database password
- **venv** - virtualenv name as projectname

3. Use it ```bash djangobuild.sh dbusername dbname dbpassword project_name```
