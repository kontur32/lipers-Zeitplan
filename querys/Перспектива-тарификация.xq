import module namespace lipersRasp = 'http://lipers.ru/modules/расписание' 
  at 'https://raw.githubusercontent.com/kontur32/lipers-Zeitplan/dev/modules/lipers-module-lipersRasp.xqm';

let $data := .

let $расписаниеДанные := $data//table[ @label = 'Расписание учителей' ]
let $словарьПредметов := $data//table[ @label = 'Кодификатор предметов' ]

return
   lipersRasp:рендерингШтатноеРасписание( $расписаниеДанные, $словарьПредметов )