let $data := . 

let $расписаниеДанные := $data//table[ @label = 'Расписание учителей']

let $номераУроков := 
  ( 
    "1", "2", "3", "4", "5", "6","7","8","9",
    "1", "2", "3","4","5", "6","7","8","9",
    "1", "2", "3","4", "5", "6","7","8","9",
    "1", "2", "3", "4", "5", "6","7","8","9",
    "1", "2", "3","4", "5", "6","7"
  )

let $result :=
  for $b in $расписаниеДанные/row[ position() >= 2 ]
  where distinct-values ($b/cell[ @label = "Учитель" ]/text())
  order by $b

return 
  <tr>
    <td> <b> { distinct-values ($b/cell [ 1 ]) } </b> </td>
      {
        for $i in $b/cell [ position() >= 3 ]
        return
        <td>{ $i }</td>
      }    
  </tr>

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
                for $i in ('Понедельник',"Вторник","Среда", "Четверг", "Пятница")
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
            <td> { $result } </td>             
      </table>
     </body>
    </html>