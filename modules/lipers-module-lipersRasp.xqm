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

declare function lipersRasp:класс-урок-день( $расписаниеДанные, $словарьПредметов ){
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
      { lipersRasp:класс-урок-день( $расписаниеДанные, $словарьПредметов ) }
    </table>
  </div>
};