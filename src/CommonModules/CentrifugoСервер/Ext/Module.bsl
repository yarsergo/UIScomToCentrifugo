﻿ 
 // Внешние методы
 #Область ПрограммныйИнтерфейс
 
 // Функция - Получить канал по номеру
 //
 // Параметры:
 //  ВиртуальныйНомер - Строка - виртуальный номер оператора (11 цифр, начиная с 7)
 // Возвращаемое значение:
 //  строка - внутренний номер оператора (4 цифры) или "news"
 //
 Функция ПолучитьКаналПоНомеру( ВиртуальныйНомер = "" ) Экспорт 
	 ДлинаВнутреннегоНомера = 4;
	 Канал = "news"; 
	 
	 Если СтрДлина(ВиртуальныйНомер) = ДлинаВнутреннегоНомера Тогда
		 Канал = ВиртуальныйНомер;
	 Иначе     
		 Канал = Прав(ВиртуальныйНомер, ДлинаВнутреннегоНомера);	
	 КонецЕсли;
	 
	 Возврат Канал;
 КонецФункции	
 
 // Функция - Послать сообщение на канал
 //
 // {
 //    "method": "publish",
 //    "params": {
 //        "channel": "news", 
 //        "data": {
 //             "text": "Hello World!",
 //				"user": "UIScom"	
 //        }
 //    } 
 // }		
 //
 // Параметры:
 //  стрЗвонка - структура - структура истории звонка
 //  ВесьЗапрос - булево - флаг отправки полного запроса в Centrifugo!
 //
 // Возвращаемое значение:
 // булево - флаг успешной отправки в Centrifugo
 //
 Функция ПослатьСообщениеНаКанал( стрЗвонка, ВесьЗапрос = Ложь) Экспорт 
	 Успешно = Истина;                                              
	 method  = "publish";
	 
	 Если стрЗвонка.Канал = "" Тогда 
		 Возврат Ложь;
	 КонецЕсли;
	 
	 channel = стрЗвонка.Канал; 
	 
	 Если ВесьЗапрос Тогда // 20.07.2022
		 text = стрЗвонка.ТелоЗапроса;  
		 СписокЗамен = ПолучитьСписокЗамен();
		 Для каждого эл Из СписокЗамен Цикл
			 text = СтрЗаменить(text, эл.Значение, эл.Представление);
		 КонецЦикла; 
	 Иначе
		 text = стрЗвонка.ВызываемыйНомер;
	 КонецЕсли;
	 
	 data = Новый Структура("text, user", text, "UIScom");
	 params = Новый Структура("channel, data", channel, data);
	 Данные = Новый Структура("method, params", method, params);
	 ТелоСтрокой = Данные_в_JSON(Данные);
	 
	 текстОшибки = ОтправитьЗапрос( ТелоСтрокой ); 
	 Успешно = (текстОшибки = "");
	 
	 Если НЕ Успешно Тогда
		 ЗаписьЖурналаРегистрации("Centrifugo", УровеньЖурналаРегистрации.Ошибка, , params, текстОшибки);
	 КонецЕсли;	
	 
	 Возврат Успешно;
 КонецФункции 
 
 #КонецОбласти
 
 // Внутренние методы
 #Область СлужебныеПроцедурыИФункции  
 
 // Функция - Данные в JSON
 //
 // Параметры:
 //  Данные - структура - структура полей для отправки 
 // 
 // Возвращаемое значение:
 //  строка - текст JSON
 //
 Функция Данные_в_JSON(Данные) 
	 ЗаписьJSON = Новый ЗаписьJSON;
	 ЗаписьJSON.УстановитьСтроку(Новый ПараметрыЗаписиJSON(ПереносСтрокJSON.Нет));
	 ЗаписатьJSON(ЗаписьJSON, Данные);
	 Возврат ЗаписьJSON.Закрыть();
 КонецФункции
 
 // Функция - Отправить HTTPзапрос
 //
 // Параметры:
 //  ТекстJSON - строка - текст JSON для отправки
 // 
 // Возвращаемое значение:
 //  строка - Текст Ошибки
 //
 Функция ОтправитьЗапрос( ТекстJSON = "" )
	 КодСостоянияОк = 200;
	 ТекстОшибки = "";  
	 
	 Сервер = Константы.СерверCentrifugo.Получить();
	 apikey = Константы.apikeyCentrifugo.Получить();
	 
	 Ресурс = "/api";
	 Таймаут = 300;
	 Попытка
		 Соединение = Новый HTTPСоединение(Сервер, , , , , Таймаут); 
	 Исключение
		 ТекстОшибки = "КодСостояния: 401; Ошибка подключения к серверу Centrifugo: " + Сервер + "
		 | " + ОписаниеОшибки();
		 Возврат ТекстОшибки;
	 КонецПопытки;
	 
	 ЗаголовокHTTP = Новый Соответствие();
	 ЗаголовокHTTP.Вставить("Content-Type", "application/json");   
	 // русские буквы - надо преобразовывать в UNIcode!
	 ЗаголовокHTTP.Вставить("Content-Charset", "utf-8"); // 22.07.2022 - не помогает!
	 ЗаголовокHTTP.Вставить("Authorization", "apikey " + apikey);  // ОБЯЗАТЕЛЬНО!
	 ЗаголовокHTTP.Вставить("Content-Length", формат(стрДлина(ТекстJSON), "ЧДЦ=; ЧН=0; ЧГ=0") );
	 ЗаголовокHTTP.Вставить("Host", Сервер);  // 20.07.2022
	 ЗаголовокHTTP.Вставить("User-Agent", "Enterprise1S/8.3");
	 
	 ЗаголовокHTTP.Вставить("Accept", "*/*"); // любой ответ!
	 ЗаголовокHTTP.Вставить("Accept-Encoding", "gzip, deflate, br");
	 
	 ЗапросHTTP = Новый HTTPЗапрос(Ресурс, ЗаголовокHTTP);
	 ЗапросHTTP.УстановитьТелоИзСтроки(ТекстJSON);
	 
	 Попытка
		 Ответ = Соединение.ОтправитьДляОбработки(ЗапросHTTP); 
	 Исключение
		 ТекстОшибки = "КодСостояния: 403; Ошибка отправки HTTP-запроса в Centrifugo!
		 |" + ОписаниеОшибки();
		 Возврат ТекстОшибки;
	 КонецПопытки;
	 
	 Если Ответ.КодСостояния <> КодСостоянияОк Тогда
		 ТекстОшибки = "КодСостояния: " + строка(Ответ.КодСостояния) + "; " + Ответ.ПолучитьТелоКакСтроку();   
	 КонецЕсли;	
	 
	 Возврат ТекстОшибки;		
 КонецФункции
 
// Функция - Получить список замен
// 
// Возвращаемое значение:
//  СписокЗначений - список замен русских фраз на английские
//
 Функция ПолучитьСписокЗамен()
	 СписокЗамен = Новый СписокЗначений;
	 СписокЗамен.Добавить("время", "time"); // сценарий (по умолчанию)
	 СписокЗамен.Добавить("рабочее", "working"); 	
	 СписокЗамен.Добавить("нерабочее", "non-working"); 
	 
	 СписокЗамен.Добавить("Начало Входящего звонка", "Begin In call"); 	
	 СписокЗамен.Добавить("Завершение звонка", "Finish call"); 
	 
	 СписокЗамен.Добавить("звонок", "call");
	 СписокЗамен.Добавить("Входящий", "Incoming"); СписокЗамен.Добавить("Исходящий", "Outcoming");
	 СписокЗамен.Добавить("Потерянный", "Lost");    
	 
	 СписокЗамен.Добавить("Абонент", "Client");     СписокЗамен.Добавить("абонента", "client");
	 СписокЗамен.Добавить("Сотрудник", "Operator"); СписокЗамен.Добавить("cотрудника", "operator");
	 СписокЗамен.Добавить("разорвал соединение", "disconnected"); 
	 СписокЗамен.Добавить("не отвечает", "no answer");  
	 СписокЗамен.Добавить("Не дозвонились до", "Did not reach the"); // завершение звонка
	 Возврат СписокЗамен;
 КонецФункции

#КонецОбласти