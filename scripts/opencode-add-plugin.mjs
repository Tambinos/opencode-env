#!/usr/bin/env node

import fs from "node:fs"
import path from "node:path"

const [configDir, spec] = process.argv.slice(2)

if (!configDir || !spec) {
  console.error("usage: opencode-add-plugin.mjs <config-dir> <plugin-spec>")
  process.exit(2)
}

function stripTrailingCommas(src) {
  let out = ""
  let inString = false
  let quote = ""

  for (let i = 0; i < src.length; i++) {
    const c = src[i]

    if (inString) {
      out += c
      if (c === "\\" && i + 1 < src.length) {
        out += src[++i]
      } else if (c === quote) {
        inString = false
      }
      continue
    }

    if (c === '"' || c === "'") {
      inString = true
      quote = c
      out += c
      continue
    }

    if (c === ",") {
      let j = i + 1
      while (j < src.length && /\s/.test(src[j])) j++
      if (src[j] === "}" || src[j] === "]") continue
    }

    out += c
  }

  return out
}

function stripJsonComments(src) {
  let out = ""
  let inString = false
  let quote = ""
  let inLine = false
  let inBlock = false

  for (let i = 0; i < src.length; i++) {
    const c = src[i]
    const next = src[i + 1]

    if (inLine) {
      if (c === "\n") {
        inLine = false
        out += c
      }
      continue
    }

    if (inBlock) {
      if (c === "*" && next === "/") {
        inBlock = false
        i++
      }
      continue
    }

    if (inString) {
      out += c
      if (c === "\\" && i + 1 < src.length) {
        out += src[++i]
      } else if (c === quote) {
        inString = false
      }
      continue
    }

    if (c === '"' || c === "'") {
      inString = true
      quote = c
      out += c
      continue
    }

    if (c === "/" && next === "/") {
      inLine = true
      i++
      continue
    }

    if (c === "/" && next === "*") {
      inBlock = true
      i++
      continue
    }

    out += c
  }

  return stripTrailingCommas(out)
}

function parse(raw) {
  if (!raw.trim()) return { $schema: "https://opencode.ai/config.json" }

  try {
    return JSON.parse(raw)
  } catch {
    return JSON.parse(stripJsonComments(raw))
  }
}

const jsonc = path.join(configDir, "opencode.jsonc")
const json = path.join(configDir, "opencode.json")
const file = fs.existsSync(jsonc) ? jsonc : fs.existsSync(json) ? json : jsonc

const raw = fs.existsSync(file) ? fs.readFileSync(file, "utf8") : ""
const config = parse(raw)

if (!config || typeof config !== "object" || Array.isArray(config)) {
  console.error(`[opencode-tools] ${file} is not a JSON object`)
  process.exit(1)
}

if (!Array.isArray(config.plugin)) config.plugin = []

const present = config.plugin.some((entry) =>
  Array.isArray(entry) ? entry[0] === spec : entry === spec,
)

if (present) process.exit(0)

fs.mkdirSync(configDir, { recursive: true })

if (fs.existsSync(file) && !fs.existsSync(`${file}.bak`)) {
  fs.copyFileSync(file, `${file}.bak`)
}

const mode = fs.existsSync(file) ? fs.statSync(file).mode & 0o777 : 0o644
config.plugin.push(spec)
fs.writeFileSync(file, `${JSON.stringify(config, null, 2)}\n`, { mode })
console.log(`[opencode-tools] enabled ${spec} in ${file}`)
