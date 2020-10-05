(:
  Функции для генерации таблиц расписания для школьников и учителей
:)

module namespace lipersRasp = 'http://lipers.ru/modules/расписание';

declare namespace iro = "http://dbx.iro37.ru";
declare namespace с = 'http://dbx.iro37.ru/сущности';
declare namespace п = 'http://dbx.iro37.ru/признаки';

declare function lipersRasp:предмет( $код as xs:string*, $кодификатор as element( table ) ){
  let $предмет := 
    $кодификатор/row[ cell[ @label = 'Код' ] = $код ]/cell[ @label = 'Предмет' ]/text()
  return
    empty( $предмет ) ?? $код || '(неизвестный код предмета)' !! $предмет
};

(:-----------------------------------------------------------------------------:)
(:
  Функции для генерации детского расписания
:)

declare function lipersRasp:списокКлассов( $расписаниеДанные ){
  let $классы := 
    $расписаниеДанные
    /row[ position() >= 3 ]
    /cell[ position() >= 3 ]/tokenize( tokenize( ., ';')[ 1 ], ',' )
  for $i in distinct-values( $классы )
  order by number( $i )
  return
    $i
};

declare function lipersRasp:спиоскКлассов( $данныеРасписания ){
  for $i in
    distinct-values(
      $данныеРасписания
      /с:учитель/п:имеетУчебноеЗанятие/с:учебноеЗанятие/п:класс/text()
    )
  order by number( replace( $i, '[А-Яа-я]', '' ) ) descending
  return $i
};

declare function lipersRasp:строкиДетскогоРасписания( $расписаниеДанные, $словарьПредметов ){
  let $классы := lipersRasp:списокКлассов( $расписаниеДанные )
  for $класс in $классы
  return
  let $урокиКласса :=
    $расписаниеДанные
    /row[ position() >= 3 ]
    /cell[ position() >= 3 ][ tokenize( tokenize( ., ';' )[ 1 ], ',' ) = $класс ]
  for $урок in 1 to 9
  return
    <tr>
      {
        if( $урок = 1 )
        then( <td rowspan="9">{ $класс } класс</td> )
        else()
      }
      <td>{ $урок } урок</td>
      {
      for $день in 1 to 5
      let $предметы := 
        $урокиКласса
        [ tokenize( @label, '-' )[ 1 ][ number( . ) = $день ] ]
        [ tokenize( @label, '-' )[ 2 ][ number( . ) = $урок ] ]
        
      let $названиеПредмета := 
          if( count( $предметы ) = 2 and string-join( $предметы/tokenize( ., ';' )[ 3 ] ) = '////'  or  count( $предметы ) <= 1 )
          then(
            for $предмет in $предметы
            (: если 4 признак "-", то добавлет ФИО учителя :)
            let $учитель :=
              if(
                tokenize( $предмет/., ';' )[ 4 ] = '-'
              )then( 
                ', уч. ' || $предмет/parent::*/cell[ @label/data() = 'Учитель' ]/text()
              )else()
            let $ученик := 
              if(
                tokenize( $предмет/., ';' )[ 5 ]
              )then( 
                ', инд. с ' || tokenize( $предмет/., ';' )[ 5 ]
              )else()
            return
              lipersRasp:предмет( tokenize( $предмет/., ';' )[ 2 ], $словарьПредметов ) ||
              $учитель || $ученик
          )
          else( 'Ошибка' )
         
        return
          <td день = '{ $день }' урок = '{ $урок }'>{ string-join( $названиеПредмета, '/' ) }</td>
  }
  </tr> 
};

(:----------------------------------------------------------------------------:)
(:
  Строки детского расписания из новой модели
:)

declare
  %public
function 
  lipersRasp:строкиДетскогоРасписания2(
     $данныеРасписания,
     $словарьПредметов,
     $params
   ){
    let $классы := 
      lipersRasp:спиоскКлассов( $данныеРасписания )
  
  for $класс in $классы
  where $класс = $params?класс
  for $урок in ( 1 to 8 )
  return
    <tr>
      {
        if( $урок =  1 )
        then(
          <td rowspan = '8'>{ $класс }</td>
        )
        else()
      }
      <td>{ $урок } урок</td>
      {
        for $день in ( 1 to 5 )
        let $записи := 
          $данныеРасписания
            /с:учитель/п:имеетУчебноеЗанятие/с:учебноеЗанятие[
              п:класс = $класс and
              п:деньНеделиНомер = $день and
              п:урокНомер = $урок
            ]
         let $предмет :=
          for $p in $записи
          let $подгруппа := $p/п:подгруппа
          group by $подгруппа
          
          for $pp in $p
          where count( $p ) > 1 ?? $pp/п:замещение = 'Z' !! true()
          let $учитель := 
            if( $подгруппа or $pp/п:публикацияФИОучителя = '-' or $pp/п:замещение = 'Z' )
            then(
              ' (' || $pp/parent::*/parent::*/п:локальноеИмя || ')' )
            else()
          return
            lipersRasp:предмет( $pp/п:предмет/text(), $словарьПредметов ) ||  $учитель 
         
         return
          <td>{ string-join( $предмет, '/' ) }</td>
      }
    </tr>
};

declare function lipersRasp:рендерингРасписаниеДетское( $расписаниеДанные, $словарьПредметов ){
  <div>
    <link rel="stylesheet" href="http://iro37.ru/res/trac-src/xqueries/saivpds/css/saivpds.css"/>
    <table border = '1px'>
      <tr>
        <th>Класс</th>
        <th>Урок</th>
        {
          for $i in ( 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница' )
          return
            <th>{ $i }</th>
        }
      </tr>
      { lipersRasp:строкиДетскогоРасписания( $расписаниеДанные, $словарьПредметов ) }
    </table>
  </div>
};


declare
  %public
function
  lipersRasp:рендерингРасписаниеДетское2(
    $расписаниеДанные,
    $словарьПредметов,
    $params,
    $ID
  )
{
  <div>
    <link rel="stylesheet" href="http://iro37.ru/res/trac-src/xqueries/saivpds/css/saivpds.css"/>
    <h2>Расписание { $params?класс } класса</h2>
    <div>Выберите класс: {
      for $i in lipersRasp:спиоскКлассов( $расписаниеДанные )
      return
        <a href = '{ $ID|| "?класс=" || $i }'>{ $i }</a>
    }</div>
    <table border = '1px'>
      <tr>
        <th>Класс</th>
        <th>Урок</th>
        {
          for $i in ( 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница' )
          return
            <th>{ $i }</th>
        }
      </tr>
      {
         lipersRasp:строкиДетскогоРасписания2( $расписаниеДанные, $словарьПредметов, $params )
      }
    </table>
  </div>
};

(:-----------------------------------------------------------------------------:)
(:
  Функции для генерации расписания учителей
:)
declare 
  %private
function lipersRasp:строкиРасписаниеУчителей( $расписаниеДанные ){
  for $учитель in $расписаниеДанные/row[ position() >= 3 ]
  where  $учитель/cell[ @label = "Учитель" ]/text()
  order by $учитель

  return 
    <tr>
      <td><b>{ $учитель/cell[ 1 ] }</b></td>
        {
          for $i in $учитель/cell[ position() >= 3 ]
          return
            <td>{ $i }</td>
        }    
    </tr>
};

declare 
  %public
function lipersRasp:рендерингРасписаниеУчителей( $расписаниеДанные ){
  let $номераУроков := 
    ( 
      "1", "2", "3", "4", "5", "6","7","8","9",
      "1", "2", "3","4","5", "6","7","8","9",
      "1", "2", "3","4", "5", "6","7","8","9",
      "1", "2", "3", "4", "5", "6","7","8","9",
      "1", "2", "3","4", "5", "6","7"
    )
  return
  <html>
      <link rel="stylesheet" href="http://iro37.ru/res/trac-src/xqueries/saivpds/css/saivpds.css"/>
      <body>
         <h2><b><center>РАСПИСАНИЕ СОТРУДНИКОВ АНО «ЛИЦЕЙ «ПЕРСПЕКТИВА» на { current-date()} г. </center></b></h2>
         <table border="1" bordercolor="black" width="100%">
      <colgroup>
        <col span="1" style="background-color:LightCyan">  </col>
        <col span="9" style="background-color:Khaki">  </col>
        <col span="18" style="background-color:LightCyan">  </col>
        <col span="27" style="background-color:Khaki">  </col>
      </colgroup>
            <tr>
               <th width="10%">Учитель</th>
              {
                for $i in ( 'Понедельник', "Вторник", "Среда", "Четверг", "Пятница" )
                return
                  <th colspan="9">{ $i }</th>
              }           
            </tr>
            <tr>    
              <th/>
                {
                for $i in $номераУроков
                return
                  <th>{ $i }</th>
                }   
            </tr>
            { lipersRasp:строкиРасписаниеУчителей( $расписаниеДанные ) }
      </table>
     </body>
    </html>
};


(:-----------------------------------------------------------------------------:)
(:
  Функции для генерации штатного расписания (тарификации)
:)

declare 
  %private
function 
  lipersRasp:строкиШтатноеРасписание( 
    $расписаниеДанные as element( table ),
    $словарьПредметов as element( table )
  ){
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
          lipersRasp:предмет( $предмет, $словарьПредметов ), 
         count( $j ),
         string-join( $поДням )
       ]
  return
    $поУчителям 
     
return
  let $учителя := $расписаниеДанные/row[ cell[ @label = "ID учителя" ]/text() ]/cell[ @label = "Учитель" ]
  for $учитель in $учителя
  let $поУчителю := $результат[ ?1 = $учитель/text() ]
  return
    (
      <tr>
        <td rowspan = "{count( $поУчителю ) + 1 }">{ $учитель/text() }</td>
        <td>Всего часов</td>
          <td id = 'total' >{ sum( $поУчителю?3 ) }</td>
          <td></td>
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
};


declare 
  %public
function lipersRasp:рендерингШтатноеРасписание( $расписаниеДанные, $словарьПредметов ){
  let $всегоЧасовПоУчителям := 
  count( 
    $расписаниеДанные/row[ position() >= 4 ][cell[@label='ID учителя']/text() ]/cell[  position() >= 3 ][ text() ]
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
      lipersRasp:строкиШтатноеРасписание( 
        $расписаниеДанные ,
        $словарьПредметов
      )
    }
    <tr>
      <td colspan = "2">Всего</td>
      <td>{ $всегоЧасовПоУчителям }</td>
      <td></td>
    </tr>
  </table>
};