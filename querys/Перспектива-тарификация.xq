declare function local:предмет( $код as xs:string*, $словарьПредметов as element( table ) ){
  $словарьПредметов/row[ cell[ @label = 'Код' ] = $код ]/cell[ @label = 'Предмет' ]/text()
};
 

let $data := .
let $расписаниеДанные := $data//table[ @label = 'Расписание учителей']
let $словарьПредметов := $data//table[ @label = 'Кодификатор предметов']

let $результат := 
  for $i in $расписаниеДанные/row
  let $учитель := $i/cell[ @label = "Учитель" ]/text()
  where $учитель and upper-case( substring( $учитель, 1, 1 ) ) = substring( $учитель, 1, 1 )
  group by $учитель

  let $поУчителям :=
    for $j in $i/cell[ position() > 2 ]
    let $предмет := $j/tokenize( text(), ';' )[ 2 ]
    let $день :=  $j/@label/tokenize( data(), '-' )[ 1 ]
    where $предмет
    group by $предмет
    let $поДням := 
      for $i in 1 to 5
      let $количествоУроковПоПредмету := count( $день[ number( . ) = $i ] )
      return
        if( $количествоУроковПоПредмету )then( $количествоУроковПоПредмету )else( '-' )
    return
       [
         $учитель, 
         local:предмет( $предмет, $словарьПредметов ), 
         count( $j ),
         string-join( $поДням )
       ]
  return
    $поУчителям 
     
let $строкиТаблицыПоУчителям := 
  let $учителя := $расписаниеДанные/row[ cell[ @label = "ID учителя" ]/text() ]/cell[ @label = "Учитель" ]
  for $учитель in $учителя
  let $поУчителю := $результат[ ?1 = $учитель/text() ]
  return
    (
      <tr>
        <td rowspan = "{count( $поУчителю ) + 1 }">{ $учитель/text() }</td>
        <td>Всего часов</td>
          <td>{ sum( $поУчителю?3 ) }</td>
          <td>{ }</td>
      </tr>,
    
    for $i in $поУчителю
    count $c
    return  
      <tr>
        <td>{ $i?2 }</td>
        <td>{ $i?3 }</td>
        <td>{ $i?4 }</td>
      </tr>
    )


return
   <table border = "1px">
    <tr>
      <td>Учитель</td>
      <td>Предмет</td>
      <td>Всего часов</td>
      <td>Часы по дням недели</td>
    </tr>
    {
      $строкиТаблицыПоУчителям
    }
    <tr>
      <td colspan = "2">Всего</td>
      
      <td>{ sum( $результат?3 ) }</td>
      <td></td>
    </tr>
  </table>