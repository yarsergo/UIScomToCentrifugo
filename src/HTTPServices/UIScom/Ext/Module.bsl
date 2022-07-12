﻿
// Функция - Incoming call /IN
// Делаем запись в рс.ИсторияЗвонков и отправляем номер входящего звонка в Centrifugo на Канал оператора!
//
// ТелоЗапроса = {
// "direction":{{direction}},
// "notification_name":{{notification_name}},
// "notification_mnemonic":{{notification_mnemonic}},
// "virtual_phone_number":{{virtual_phone_number}},
// "notification_time":{{notification_time}},
// "scenario_name": {{scenario_name}},
// "start_time":{{start_time}},
// "called_phone_number":{{called_phone_number}},
// "calling_phone_number":{{calling_phone_number}},
// "call_session_id":{{call_session_id}}
// }
//
// Параметры:
//  Запрос - HttpЗапрос - входящий запрос - получаем Тело 
// 
// Возвращаемое значение:
// HTTPСервисОтвет - ответ на входящий запрос
//
Функция IncomingCall_IN(Запрос)
  КодСостояния = 200;  // по умолчанию Ok
  Причина = ""; 
  
  ТелоЗапроса = Запрос.ПолучитьТелоКакСтроку(); 
  
  структураПолей = UIScomСервер.JSON_в_Данные(ТелоЗапроса);
  
  Если ПустаяСтрока(ТелоЗапроса) 
	  Или структураПолей = Неопределено Тогда
	  Причина = "Empty body of request or body not JSON-text!";
	  КодСостояния = 400;
	  
  ИначеЕсли типЗнч(структураПолей) <> тип("Структура") Тогда 
	  Причина = "Error in JSON. Not structure!";
	  КодСостояния = 400;
	  
  Иначе // --------------------------------------------------------   
	  стрЗвонка = UIScomСервер.ПолучитьСтруктуруПолейИсторииЗвонков(структураПолей);
	  Если НЕ стрЗвонка.Свойство("Входящий") Тогда
		  стрЗвонка.Добавить("Входящий", Истина);
	  КонецЕсли;
	  
	  Если стрЗвонка.Входящий Тогда
		  Канал = CentrifugoСервер.ПолучитьКаналПоНомеру( стрЗвонка.Номер );   
		  стрЗвонка.Добавить("Канал", Канал);                                               
		  
		  Отправлен = CentrifugoСервер.ПослатьСообщениеНаКанал( стрЗвонка ); // отправка !!!
		  стрЗвонка.Добавить("Отправлен", Отправлен);                                       
		  
		  Если НЕ Отправлен Тогда 
			  Причина = "Error Centrifugo send to channel: " + Канал + " !";
			  КодСостояния = 417;
		  КонецЕсли;
		  
	  КонецЕсли;
	  
	  стрЗвонка.Добавить("ТелоЗапроса", ТелоЗапроса); // весь запрос
	  РегистрыСведений.ИсторияЗвонков.СоздатьЗапись( стрЗвонка );
  КонецЕсли;	
  
  Ответ = Новый HTTPСервисОтвет(КодСостояния, Причина);
  Возврат Ответ;
КонецФункции  

// Функция - Outcoming call OUT
// Делаем запись в рс.ИсторияЗвонков, НО ничего не отправляем в Centrifugo!
//
// Параметры:
//  Запрос - HttpЗапрос - входящий запрос - получаем Тело 
// 
// Возвращаемое значение:
// HTTPСервисОтвет - ответ на входящий запрос
//
Функция OutcomingCall_OUT(Запрос)
	Ответ = IncomingCall_IN(Запрос); 
	Возврат Ответ;
КонецФункции

// Функция - Record end REC
// Получаем существующую запись по измерениям и Добавляем данные!
//
// Параметры:
//  Запрос - HttpЗапрос - входящий запрос - получаем Тело 
// 
// Возвращаемое значение:
// HTTPСервисОтвет - ответ на входящий запрос
//
Функция RecordEnd_REC(Запрос)
  КодСостояния = 200;  // по умолчанию Ok
  Причина = ""; 
  
  ТелоЗапроса = Запрос.ПолучитьТелоКакСтроку(); 
  
  структураПолей = UIScomСервер.JSON_в_Данные(ТелоЗапроса);
  
  Если ПустаяСтрока(ТелоЗапроса) 
	  Или структураПолей = Неопределено Тогда
	  Причина = "Empty body of request or body not JSON-text!";
	  КодСостояния = 400;
	  
  ИначеЕсли типЗнч(структураПолей) <> тип("Структура") Тогда 
	  Причина = "Error in JSON. Not structure!";
	  КодСостояния = 400;
	  
  Иначе // --------------------------------------------------------   
	  стрЗвонка = UIScomСервер.ПолучитьСтруктуруПолейИсторииЗвонков(структураПолей);
	  
	  стрЗаписи = РегистрыСведений.ИсторияЗвонков.ПолучитьЗапись(стрЗвонка.Номер, стрЗвонка.Входящий, стрЗвонка.ИдСессии); 
	  Если стрЗаписи = Неопределено Тогда
	 	  стрЗвонка.Добавить("ТелоЗапроса", ТелоЗапроса); // весь запрос
		  стрЗаписи = стрЗвонка;
	  Иначе	  
		  Для каждого эл Из стрЗвонка Цикл 
			стрЗаписи.Вставить( эл.Ключ, эл.Значение);	// добавление данных в готовую запись!   
		  КонецЦикла;
	  КонецЕсли;
	  
	  РегистрыСведений.ИсторияЗвонков.СоздатьЗапись( стрЗаписи );
  КонецЕсли;	
  
  Ответ = Новый HTTPСервисОтвет(КодСостояния, Причина);
  Возврат Ответ;
КонецФункции