/**
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

io.nodekit.test.logconsole("STARTING SAMPLE SCRIPTING APPLICATION");


var subIndex = require("./subdirectory");

io.nodekit.test.logconsole("subdirectory/index.js: " + subIndex);

var functionExport = require("./function_export");

functionExport()

setInterval(function() {

    io.nodekit.test.logconsole("interval fire");
    io.nodekit.test.logconsole("native set property: " + io.nodekit.test.nativeKey);

}, 2000)

var timerId = setTimeout(function() {
            
    io.nodekit.test.logconsole("timeout fire " + timerId);
    
}, 1000)
