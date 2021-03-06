# Copyright 2013 Tasos Laskos <tasos.laskos@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

searchModules = ( val ) ->
    $("#settings ").show()

    if( val != '' )
        $("#settings .module:not(:icontains(" + val + "))").hide()
    else
        $("#settings .module").show()

jQuery ->
    $('#settings input#search').keyup ->
        searchModules $(this).val()

    $('#settings #profile button.check').click ->
        $('#settings .module input:visible:checkbox').attr('checked','checked')
        false
    $('#settings #profile button.uncheck').click ->
        $('#settings .module input:visible:checkbox').removeAttr('checked')
        false
