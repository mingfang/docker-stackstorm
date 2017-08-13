'use strict';
angular.module('main')
  .constant('st2Config', {

    hosts: [{
      name: 'StackStorm',
      url: '//:80/api',
      auth: '//:80/auth'
    }]
  });
