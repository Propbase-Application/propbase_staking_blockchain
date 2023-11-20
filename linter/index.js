const fs = require("fs");
const path = process.argv[2]; // get the file path from command line arguments

if (!path) {
  console.log("Please provide a file path");
  process.exit(1);
}

fs.readFile(path, "utf8", function (err, data) {
  if (err) {
    return console.log(err);
  }
  let result = data
    .replace(/(?<=\S)(\+|\-|\*|\/|\=\=|\!\=|\=)(?=\S)/g, " $1 ")
    .replace(/(?<=\S)(\+|\-|\*|\/|\=\=|\!\=|\=)(?=\S)/g, " $1")
    .replace(/,( )+(?!\n)/g, ", ")
    .replace(/,( )+\n/g, ",\n")
    .replace(/=( )+=/g, "==");

  fs.writeFile(path, result, "utf8", function (err) {
    if (err) return console.log(err);
  });
});
