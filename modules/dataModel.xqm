module namespace model = 'http://lipers.ru/modules/модельДанных';

declare namespace iro = "http://dbx.iro37.ru";
declare namespace с = 'http://dbx.iro37.ru/сущности';
declare namespace п = 'http://dbx.iro37.ru/признаки';

declare function model:записьРасписания( $запись as xs:string, $params ){
  let $признаки := tokenize( $запись, ';' )
  let $названияПризнаков :=
    if( $params?признаки )
    then(
      $params?признаки 
    )
    else(
      (
        'класс',
        'предмет',
        'кабинет',
        'подгруппа',
        'публикацияФИОучителя',
        'замещение'
      )
    )
    
  return
      (
        for $i in $признаки
        count $c
        for $j in tokenize( $i, ',' )
        let $текущийПризнак :=
          if( $названияПризнаков[ $c ] )
          then( $названияПризнаков[ $c ] )
          else( 'признак_' || $c )
        return
          element { xs:QName('п:' || $текущийПризнак ) } { $j }
      )
};

declare function model:учебноеЗанятие ( $cell as element( cell ), $params ){
    let $id := $cell/@label/data()
    where matches( $id, '^[1-5]-[1-9]' )
    let $признаки := tokenize( $id, '-' )
    
    return
      element п:имеетУчебноеЗанятие {
        element с:учебноеЗанятие {
          attribute id { $cell/parent::*/cell[ @label = 'ID учителя' ] || '-' || $id },
          attribute type { 'http://dbx.iro37.ru/онтология/УчебноеЗанятие' },
          element п:деньНеделиНомер{ $признаки[ 1 ] },
          element п:урокНомер{ $признаки[ 2 ] },
          model:записьРасписания( $cell/text(), $params )
        }
      }
  };
  
declare function model:учитель ( $row as element( row ), $params ){
    element с:учитель {
      attribute id { $row/cell[ @label = 'ID учителя' ]/data() },
      attribute type { 'http://dbx.iro37.ru/онтология/Учителя' }, 
      element п:локальноеИмя { $row/cell[ @label = 'Учитель' ]/text() },
      $row/cell[ text() ]/model:учебноеЗанятие( ., $params )
    }
  };

declare function model:расписание( $table as element( table ), $params ){
  element с:расписание {
    attribute id { $table/@label/data() },
    attribute type { 'http://dbx.iro37.ru/онтология/Расписание' },
    $table/row[ cell[ @label = 'ID учителя' ]/text() ]/model:учитель( ., $params )
  }
};

(:
  трансформирует расписание из формата element(с:расписание) в RDF/XML
:)
declare 
  %public
function model:расписаниеRDF(
  $расписание as element(с:расписание),
  $календарныйГод  as xs:integer,
  $номерКалендарнойНедели as xs:integer,
  $учебныйГод as xs:string, 
  $номерУчебнойНедели as xs:integer
)
{
  <rdf:RDF>{
    for $i in $расписание/с:учитель
    let $идентификаторУчителя := 
      'http://lipers.ru/схема/сущности/учителя/#' || $i/@id/data()
    return
      <rdf:Description rdf:about="{$идентификаторУчителя}">
        <rdf:type rdf:resource="http://lipers.ru/схема/онтология/Учитель"/>
        <признак:локальноеИмя>{$i/п:локальноеИмя/text()}</признак:локальноеИмя>
        {
          for $ii in $i/п:имеетУчебноеЗанятие/с:учебноеЗанятие
          return
            <признак:имеетУчебноеЗанятие>
              <rdf:Description>
                  <rdf:type rdf:resource="http://lipers.ru/схема/онтология/УчебноеЗанятие"/>
                  <признак:калерндарныйГод>{$календарныйГод}</признак:калерндарныйГод>
                  <признак:учебныйГод>{$учебныйГод}</признак:учебныйГод>
                  
                  <признак:календарнаяНеделяНомер>{$номерКалендарнойНедели}</признак:календарнаяНеделяНомер>
                  <признак:учебнаяНеделяНомер>{$номерУчебнойНедели}</признак:учебнаяНеделяНомер>
                  <признак:деньНеделиНомер>{$ii/п:деньНеделиНомер/text()}</признак:деньНеделиНомер>
                  <признак:урокНомер>{$ii/п:урокНомер/text()}</признак:урокНомер>
                  <признак:названиеКласса>{$ii/п:класс/text()}</признак:названиеКласса>
                  <признак:названиеПодгруппы>{$ii/п:подгруппа/text()}</признак:названиеПодгруппы>
                  <признак:названиеПредмета>{$ii/п:предмет/text()}</признак:названиеПредмета>
              </rdf:Description>
            </признак:имеетУчебноеЗанятие>
          }
      </rdf:Description>
    }</rdf:RDF>
};
