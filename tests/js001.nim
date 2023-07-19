import ../src/js/quickjs

const JS_STRING = """
console.log("Hello quickjs!");
"""

var 
 runtime = newJSRuntime()
 context = newJSContext(runtime)

echo context.eval(JS_STRING)