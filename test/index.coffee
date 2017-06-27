chai = require "chai"
should = chai.should()
spawn = require("better-spawn")

api = require("../src/index.coffee")


options = silent: true

describe "linkall", ->
  describe "API", ->
    it "should work", ->
     
  describe "CLI", ->
    testOutput = (cmd, expectedOutput, done, std="out") ->
      child = spawn cmd, stdio:"pipe"
      if std == "out"
        std = child.stdout
      else
        std = child.stderr
      std.setEncoding("utf8")
      output = []
      std.on "data", (data) ->
        lines = data.split("\n")
        lines.pop() if lines[lines.length-1] == ""
        output = output.concat(lines)
      std.on "end", () ->
        for line,i in expectedOutput
          line.should.equal output[i]
        done()
      return child
    it "should work", ->