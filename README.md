# Prometheus

Deploy a Prometheus server for CI Analytics on Travis to Heroku. This Prometheus
server currently only supports 1 scraper for probot.

## Requirements
- This project will require docker
- We will also need a heroku client and account setup with Heroku.com

## Local Setup

```sh
script/build.sh
script/server_local.sh
```

## Deploy to Heroku

### One Time Setup
1. Go to the root of this project to execute these commands.
1. Login to Heroku : `heroku login`
1. Create a new project, where myuser is a username or org: `heroku apps:create myuser-prom`
1. Configure `PROBOT_HOST` which is the hostname of your heroku probot app url exist:
   ```sh
   heroku config:set PROBOT_HOST=myuser-probot.herokuapp.com
   ```

### Publish
- Run `script/publish.sh`

### Demo Scraper

Setup a demo scraper with Probot following [these steps](WEB1066-probot-prom.md).

## Contributing

If you have suggestions for how this project could be improved, or want to report a bug, open an issue! We'd love all and any contributions.

For more, check out the [Contributing Guide](CONTRIBUTING.md).

## License

[ISC](LICENSE) © 2018 Edward Raigosa <wenlock@github.com>
