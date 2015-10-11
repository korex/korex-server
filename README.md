# xat-server ![npm-deps](https://david-dm.org/iiegor/xat-server.svg) [![releases](https://img.shields.io/github/release/iiegor/xat-server.svg)](https://github.com/iiegor/xat-server/releases)
> A Node.js private server for xat.com 

This is supposed to be a xat private server built on top of Node.js that emulates the full functionality of the original server.

<div align="center">
  <img src="http://i.imgur.com/9nxO0PA.png">
</div>

## Install
You can get the latest stable release from the [releases](https://github.com/iiegor/xat-server/releases) page. Once you've downloaded it, you are ready to run the following commands:
```sh
$ cd xat-server
$ npm install
```
Obviously, if you want to try the latest version of xat-server, you can clone the master branch but can have bugs because it's a development branch, so don't use it for production.

The server depends on [Node.js](http://nodejs.org/), [npm](http://npmjs.org/) and other packages that are downloaded and installed during the installation process.

## Run
Execute this command to start the server.
```sh
$ script/run
```
If you want to install a plugin, add it to ``packageDependencies`` in the package.json with the respective version.

Example:
```json
{
  ...
  "packageDependencies": {
    "my-plugin": "0.1.0"
  }
}
```
and run ``$ script/install``.

## Contributors
* **Iegor Azuaga** (dextrackmedia@gmail.com)

### How to contribute
You can contribute to the project by cloning, forking or starring it. If you have any bug, open an issue or if you have an interesting thing you want to implement into the official repository, open a pull request.
