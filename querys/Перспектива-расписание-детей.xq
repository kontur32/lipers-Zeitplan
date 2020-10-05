(: Расписание обучающихся (c) С.С. Мишуров :)

import module namespace model = 'http://lipers.ru/modules/модельДанных' 
  at 'https://raw.githubusercontent.com/kontur32/lipers-Zeitplan/dev/modules/dataModel.xqm';
  
import module namespace lipersRasp = 'http://lipers.ru/modules/расписание' 
  at 'https://raw.githubusercontent.com/kontur32/lipers-Zeitplan/dev/modules/lipers-module-lipersRasp.xqm';

declare variable $params external;
declare variable $ID external;

let $data := .

let $списокПризнаков := $data//table[ @label = 'Признаки' ]

let $словарьПредметов := $data//table[ @label = 'Кодификатор предметов' ]  

let $расписаниеДанные := 
  model:расписание(
     $data//table[ @label = 'Расписание учителей' ],
     map{
       'признаки' : $списокПризнаков/row/cell[ @label = 'Признак' ]/text()
     }
   )
      
return
 lipersRasp:рендерингРасписаниеДетское2( $расписаниеДанные, $словарьПредметов, $params, $ID )