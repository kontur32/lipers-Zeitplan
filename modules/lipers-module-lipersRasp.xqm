(:
  Функции для генерации таблиц расписания для школьников и учителей
:)

module namespace lipersRasp = 'http://lipers.ru/modules/расписание';

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
    /row[ position() >= 4 ]
    /cell[ position() >= 3 ]/tokenize( tokenize( ., ';')[ 1 ], ',' )
  for $i in distinct-values( $классы )
  order by number( $i )
  return
    $i
};

declare function lipersRasp:строкиДетскогоРасписания( $расписаниеДанные, $словарьПредметов ){
  let $классы := lipersRasp:списокКлассов( $расписаниеДанные )
  for $класс in $классы
  return
  let $урокиКласса :=
    $расписаниеДанные
    /row[ position() >= 4 ]
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

declare function lipersRasp:рендерингРасписаниеДетское( $расписаниеДанные, $словарьПредметов ){
  <div>
    <link rel="stylesheet" href="http://iro37.ru/res/trac-src/xqueries/saivpds/css/saivpds.css"/>
    <table border = '1px'>
      <tr>
        <th>Класс</th>
        <th>Урок</th>
        {
          for $i in ( 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница')
          return
            <th>{ $i }</th>
        }
      </tr>
      { lipersRasp:строкиДетскогоРасписания( $расписаниеДанные, $словарьПредметов ) }
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
  where distinct-values( $учитель/cell[ @label = "Учитель" ] )
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
