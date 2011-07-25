# Pat the Campfire Bot

Is what it is, does what it says.

node.js so that it runs on Heroku. What do you know about bacon strips?

There are lots of dangling features, some extraneous code and the tests and
specs are more like sanity checks. Feel free to ignore anything ugly. 

This is my, "hey, I should learn node.js" project and most of it was written in
a burst of activity over the weekend of 2011-07-23.
 
## dependencies

Pat the bot is developed against: 

* Javascript
  * node - 0.4.7
  * npm - 1.0.18
  * underscore - 1.1.7
  * dom-js - 0.0.1
  * mongoose - 1.7.3
  * jasmine-node - 1.0.6 (development)
* Ruby
  * heroku - 2.3.6
  * foreman - 0.18.0

## setup

### local

#### 1. install node

make sure you have node installed. **Version 0.4.7** if you want to run on heroku. 

    brew install node -v0.4.7

Do whatever it says to get your `NODE_PATH` env variable set up.

#### 2. install [npm](http://npmjs.org/)

run the script, that should be enough to get started.

#### 3. clone the repo

that's a secret

#### 4. install dependencies

I think you cd into the project directory and type `npm install .`. Not sure, but 
I have them installed, so maybe that worked? YMMV. 

To install mongo, all I did was `brew install mongo` and everything just worked.

#### 5. (optional) heroku support

You'll need ruby for this. Get it. I recommend [rvm](http://rvm.beginrescueend.com/).

1. `gem install heroku`
2. `gem install foreman`

That's all.

### heroku

1. `git push heroku master`
2. setup 30m ping on http://www.montastic.com/ to make sure the app doesn't get shut off. Heroku 
automatically turns off any dynos that haven't had a request in the last hour.

## hacking

### local env

I keep a .profile file in my project directory and source it in my shell before
I start working. This lets me keep private stuff out of the code. It looks like this:

    export campfire_bot_token=12345thisisthetokencampfiregavemeweirdhuh
    export campfire_bot_account=zoomakroom
    export campfire_bot_room=100000     # staging
    # export campfire_bot_room=900000   # production
    export campfire_logging_room=100000 # bot chatter
    export PATH=$(npm bin):$PATH

I think that last PATH=$(npm bin):$PATH line is what keeps me, node, foreman,
and npm happy in my local dev environment.

Wherever you deploy, you'll need those four `campfire_*` environment variables.

### running the app

Code you write lives in src/. Everything in lib/ is either straight vendored,
or generated by `cake build` or `foreman start coffee`.

When working on the code, running `foreman start coffee` is recommended to make
sure lib/ stays up to date. To run the application, run `node lib/bot.js` or
`foreman start web`. Plain `foreman start` will run the coffee script updater and 
the web service, but the code won't be up to date when it starts (race condition) 
and the application server doesn't auto-load updated modules. So, you'll have to 
stop and restart the server to see your changes.

### plugins

Plugins live in `src/plugins`. All plugins export an object with a `listen`
property which is a function. A basic echo plugin would look like this: 

`src/plugins/echo.coffee`

    module.exports = 
      listen: (message, room) -> room.speak(message.body, console.log)

The listen method should take two arguments, `message` the message object
handed over from Campfire and `room`, the Campfire room the message came from.

If you want to access the storage classes (User, Quote, Counter, etc.) you will
have to require `./lib/store` in the plugin. Take a look at
`src/plugins/phrases.coffee` for an example.

- - -

Based on ["Quack-Bot: a campfire bot for Quick Left"](http://quickleft.com/blog/building-quick-bot)
