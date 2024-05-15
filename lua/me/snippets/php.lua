return {
  debug = "Util::getLogger($0)->debug($1);",
  warn = "Util::getLogger($0)->debug($1);",
  info = "Util::getLogger($0)->debug($1);",
  error = "Util::getLogger($0)->debug($1);",

  ["if"] = "if ($1) {\n\t$2\n}",
  ["elseif"] = "else if ($1) {\n\t$2\n}",
  ["else"] = "else {\n\t$0\n}",

  foreach = "foreach ($1 as $2) {\n\t$0\n}",

  try = "try {\n\t$0\n} catch ($1) {\n\t$2\n}",
}
