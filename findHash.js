#!/usr/bin/env node

function f1(n, byte, c) {
  for (var bitIndex = 0; bitIndex <= 7; bitIndex++) {
    var bit = (byte >> bitIndex) & 1;
    if (bit + ((n - bit) & ~1) == n) {
      n = (n - bit) >> 1;
    } else {
      n = ((c - bit) ^ n) >> 1;
    }
  }
  return n;
}

function genPassword(str, hash) {
  for (var byteIndex = str.length - 1; byteIndex >= 0; byteIndex--) {
    hash = f1(hash, str.charCodeAt(byteIndex), 0x105C3);
  }

  var n1 = 0;
  while (f1(f1(hash, n1 & 0xFF, 0x105C3), n1 >> 8, 0x105C3) != 0xA5B6) {
    if (++n1 >= 0xFFFF) {
      println("Failed to find a key!");
      return "";
    }
  }

  n1 = Math.floor(((n1 + 0x72FA) & 0xFFFF) * 99999.0 / 0xFFFF);
  var n1str = ("0000" + n1.toString(10)).slice(-5); // this will be used at the end

  var temp = parseInt(n1str.slice(0,-3) + n1str.slice(-2) + n1str.slice(-3, -2), 10);
  temp = Math.ceil((temp / 99999.0) * 0xFFFF);
  temp = f1(f1(0, temp & 0xFF, 0x1064B), temp >> 8, 0x1064B);

  for (byteIndex = str.length - 1; byteIndex >= 0; byteIndex--) {
    temp = f1(temp, str.charCodeAt(byteIndex), 0x1064B);
  }

  var n2 = 0;
  while (f1(f1(temp, n2 & 0xFF, 0x1064B), n2 >> 8, 0x1064B) != 0xA5B6) {
    if (++n2 >= 0xFFFF) {
      println("Failed to find a key!");
      return "";
    }
  }

  n2 = Math.floor((n2 & 0xFFFF) * 99999.0 / 0xFFFF);
  var n2str = ("0000" + n2.toString(10)).slice(-5);

  var password = n2str.charAt(3) + n1str.charAt(3) + n1str.charAt(1)
    + n1str.charAt(0) +       "-"       + n2str.charAt(4)
    + n1str.charAt(2) + n2str.charAt(0) +       "-"
    + n2str.charAt(2) + n1str.charAt(4) + n2str.charAt(1)
    + "::1";
  return password;
}

var child_process = require('child_process');
function genFromMathId(mathId, hash) {
  var activationKey = "1234-1234-123456";
  var password = genPassword(mathId + "$1&" + activationKey, hash);
  var input = `\n${activationKey}\n${password}\n\n`;
  console.log(hash.toString(16))
  console.log(input)
  console.log(`${child_process.spawnSync('wolfram',[],{input:input}).stdout}`)
  //var program = child_process.spawn('wolframscript');
  //var socket = program.stdout.on('data',(data)=>console.log(`${data}`))
  //var closer = program.on('exit',(code)=>global.list.splice(global.list.indexOf(hash),1))
  //program.stdin.write(input);
}

var list = [];
var start = parseInt(process.argv[2]);
var end = parseInt(process.argv[3]);
console.log(start,end)
for (var hash=start; hash < end; hash++){
  list.push(hash)
}
//list = [0x0000]

//console.log(list)

list.forEach((hash)=>genFromMathId("6515-89354-81500",hash))

//console.log("list:\n")
//console.log(list)
//
// Hash for Mathematica 11.1.? is 0x42DD;
// Hash for Mathematica 11.0.1 is 0x25DB
