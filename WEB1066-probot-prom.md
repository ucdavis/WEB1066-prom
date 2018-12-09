# Introduction

This document will help us deliver our metrics lesson in module 4. We will use
the code snippets below to build up our scraper client for Prometheus with our
Probot sample code.

This document assumes that Probot is installed and deployed to Heroku as was shown in previous lessons.

## 1. Test Data

Collect the JSON payload from a check runs API call by looking at the installed Probot app on your org or user account. If no API calls exist yet, make sure to perform a build to generate the latest payload to work with.

Copy the results into the project project as a file called:
```
test/fixtures/check_run.completed.json
```

This will be the basis for our test data.

## 2. Create Test Functions

Make sure your project is building and testing normally by running `npm run test`. Now lets add the following test functions to `test/index.test.js`.

Add a variable constant to hold the path to the test fixture.
```
const checkRunCompletedPayload = require('./fixtures/check_run.completed.json')
```

Add a unit test for the new event.
```js
 test('process check_run completed event', async () => {
   // Simulates delivery of an issues.opened webhook
   await app.receive({
     name: 'check_run.completed',
     payload: checkRunCompletedPayload
   })
 })
```

Now you should have 1 failing unit test when you run `npm run test`. Lets fix that in the next steps.

## 3.  Add Router

Edit the `./index.js` file.

Add the router that will display the metrics from the probot app at the `/probot/metrics` endpoint.

```js
// Get an express router to expose new HTTP endpoints
const router = app.route('/probot')
```

## 4. Setup The Scraper

Setup the Prometheus scraper with `prom-client` from https://github.com/siimon/prom-client

```js
  // https://github.com/siimon/prom-client
  // prometheus metrics
  const client = require('prom-client')
  const Registry = client.Registry
  const register = new Registry()
  const collectDefaultMetrics = client.collectDefaultMetrics
  
  // Probe every 5th second.

  collectDefaultMetrics({register,
    timeout: 5000,
    prefix: 'default_'
  })
```

## 5. Setup The Summary Metric Type

The [Summary Metric Type](https://prometheus.io/docs/concepts/metric_types/#summary) will be used to aggregate build data from the checks API by Probot.

```js
// register metrics on startup
  const prom = new client.Summary({
    name: 'builds_duration_ms',
    help: 'The number of builds that have executed',
    maxAgeSeconds: 60, // 1 minute sliding window
    ageBuckets: 100,   // for 100 builds
    labelNames: [
      'action',  // action
      'name',
      'check_run_status',
      'check_run_conclusion',
      'repository_full_name',
      'repository_name'
    ],
    registers: [register]
  })
```

## 6. Add The `/metrics` Route

The scraper route will be used by Prometheus to collect the metrics from Probot. Note there is no security here
so you'll have to setup security if you have private data you are transmitting.

```js
  router.get('/metrics', (req, res) => {
    app.log('GET -> metrics called.')
    res.set('Content-Type', register.contentType)
    res.end(register.metrics())
  })
```

## 7. Capture the Check Run Event

Capture the `check_run.completed` event from the GitHub App with the running Probot app. We've added some logging to make it easy to debug in the Heroku logs.

```js
  app.on('check_run.completed', async context => {
    app.log('check_run.completed -> called ')
    // app.log(JSON.stringify(context))

    const observation = {
      action: context.payload.action, // .action
      name: context.payload.check_run.name,
      check_run_status: context.payload.check_run.status,
      check_run_conclusion: context.payload.check_run.conclusion,
      repository_full_name: context.payload.repository.full_name, // repository.full_name
      repository_name: context.payload.repository.name
    }
    const duration = new Date(context.payload.check_run.completed_at) - new             Date(context.payload.check_run.started_at)

    app.log('observation.action -> ' + observation.action)
    app.log('observation.name -> ' + observation.name)
    app.log('observation.check_run_status -> ' + observation.check_run_status)
    app.log('observation.check_run_conclusion -> ' + observation.check_run_conclusion)
    app.log('observation.repository_full_name -> ' + observation.repository_full_name)
    app.log('observation.repository_name -> ' + observation.repository_name)
    app.log('duration -> ' + duration)

    prom.observe(observation, duration)
    app.log('check_run.created -> done')
  })

```

## 8. Add a Rest Route

A reset route can be handy when you need to test metrics from Prometheus and you need to validate your numbers.
Reseting the counters will allow you to observe the `/metrics` endpoint in short windows for valid counters.

```js
  // Lets test incrementing the build count
  router.get('/test_count', (req, res) => {
    app.log('GET -> /reset.')
    prom.reset()

    res.send('Counter reset ' + new Date())
  })
```

## 9. Add Keep Alive

A ping keep alive will allow you to run your Heroku apps for Prometheus and Probot continuously. However on
free Heroku accounts this will be collectively limited to the billing setup on Heroku. Free accounts typically only
get 540 free hours. Don't configure the Heroku Probot App environment options for `APP_URL` and `PROM_URL` if you
want to save your hours. However, do note that the metrics collected will only persist till the next time the
Prometheus app on Heroku is restarted. Alternative solutions should be used to persist the Prometheus data if you
plan to try this in a production environment, as well as steps to secure the environments.

```js
  // Ping router
  router.get('/ping', (req, res) => {
    res.send('pong')
    app.log('pong response')
  })

  // keep alive with Interval
  // Lets keep the prometheus and this app alive
  // Not this will use up all 540 hours in one month within about 14 days
  // and will not allow for troubleshooting unless you upgrade your account
  var http = require('http')
  if (process.env.APP_URL) {
    app.log('setting up timer for this app -> ' + process.env.APP_URL)
    setInterval(() => {
      app.log('requesting ping on -> ' + process.env.APP_URL + '/probot/ping')
      http.get(process.env.APP_URL + '/probot/ping')
    }, 300000) // every 5 minutes (300000)
  }

  if (process.env.PROM_URL) {
    app.log('setting up timer for prometheus -> ' + process.env.PROM_URL)
    setInterval(() => {
      app.log('requesting GET on -> ' + process.env.PROM_URL)
      http.get(process.env.PROM_URL)
    }, 300000) // every 5 minutes (300000)
  }
```

## 10. Deploy for Testing

It's easy to test and deploy this code both locally and on Heroku.
If you're normally done, you'll simply merge and let Travis deploy your code.

### Test it locally
```
npm run test
```

### Build it with Docker

```
docker build -t web1066_probot
```

### Run a Local instance with Docker

```
docker run --rm -p 3000:3000 \
                     -e APP_ID=00000 \
                     -e WEBHOOK_SECRET=production \
                     -e LOG_LEVEL=debug \
                     -e PRIVATE_KEY="$(cat temp/*.private-key.pem)" \
                     -e APP_URL=http://localhost:3000 \
                     -v "$(pwd):/home/node/probot-hello" \
                    web1066_probot
```

### Deploy to Heroku without Travis

```
git push heroku prom_metrics:master
```
