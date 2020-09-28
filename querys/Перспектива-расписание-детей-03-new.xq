
import module namespace lipersRasp = 'http://lipers.ru/modules/расписание' 
  at '../modules/lipers-module-lipersRasp.xqm';


let $data := .

let $расписаниеДанные := $data/table[ @label = 'Расписание учителей' ]

let $словарьПредметов := $data/table[ @label = 'Кодификатор предметов' ]  
      
return
 lipersRasp:рендерингРасписаниеДетское( $расписаниеДанные, $словарьПредметов )