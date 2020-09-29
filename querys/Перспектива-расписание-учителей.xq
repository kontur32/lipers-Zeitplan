import module namespace lipersRasp = 'http://lipers.ru/modules/расписание' 
  at 'https://raw.githubusercontent.com/kontur32/lipers-Zeitplan/dev/modules/lipers-module-lipersRasp.xqm';

let $data := . 

let $расписаниеДанные := $data//table[ @label = 'Расписание учителей']
    
return
  lipersRasp:рендерингРасписаниеУчителей( $расписаниеДанные )