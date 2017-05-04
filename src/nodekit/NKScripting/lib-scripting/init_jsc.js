/*
 * nodekit.io
 *
 * Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

this.process = this.process || {}
var process = this.process;

process.platform = process.platform || "darwin"
process.type = "main"
process.versions = {}

this.console = this.console || function () { };

console.log = function(msg, label) { NKScriptingBridge.log(msg, "Info", label || {} ) };
console.log.debug = function(msg, label) { NKScriptingBridge.log(msg, "Debug", label || {}) };
console.log.info = function(msg, label) { NKScriptingBridge.log(msg, "Info", label || {}) };
console.log.notice = function(msg, label) { NKScriptingBridge.log(msg, "Notice", label || {}) };
console.log.warning = function(msg, label) { NKScriptingBridge.log(msg, "Warning", label || {}) };
console.log.error = function(msg, label) { NKScriptingBridge.log(msg, "Error", label || {}) };
console.log.critical = function(msg, label) { NKScriptingBridge.log(msg, "Critical", label || {}) };
console.log.emergency = function(msg, label) { NKScriptingBridge.log(msg, "Emergency", label || {}) };
