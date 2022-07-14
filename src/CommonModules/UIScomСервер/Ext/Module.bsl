﻿
// ПОЛЯ УВЕДОМЛЕНИЙ по звонкам от UIScom описаны на странице:
// https://help.synergycrm.ru/integratsiya-s-uis 

// Внешние методы
#Область ПрограммныйИнтерфейс

// Функция - JSON в Данные
//
// Параметры:
//  ТелоСтрокой	- Строка - JSON - текст, полученный в запросе
// 
// Возвращаемое значение:
//  Структура - структура полей ИмяПоля = ЗначениеПоля
//
Функция JSON_в_Данные(ТелоСтрокой) Экспорт
	Результат = Неопределено;
	
	ЧтениеJSON = Новый ЧтениеJSON;
	Попытка
		ЧтениеJSON.УстановитьСтроку(ТелоСтрокой);
		Результат = ПрочитатьJSON(ЧтениеJSON);
	Исключение
		Результат = Неопределено;
	КонецПопытки;
	ЧтениеJSON.Закрыть();
	
	Возврат Результат;
КонецФункции

// Функция - Получить структуру полей истории звонков
// делаем нужные преобразования значений в другой тип
//
// Параметры:
//  структураПолей - Структура - поля UIScom из HTTP-уведомлений
// 
// Возвращаемое значение:
//  Структура - Структура полей регистра сведений ИсторияЗвонков
//
Функция ПолучитьСтруктуруПолейИсторииЗвонков(структураПолей) Экспорт 
	стрПолейЗвонков = Новый Структура;
	
	// "Период" из строки "2018-12-18 12:45:59" >> "20181218124559" >> Дату и время
	стрЗаменДаты = "-,:, ";
	МассивЗаменДаты = СтрРазделить(стрЗаменДаты, ",");
	
	СоотвПолей = ПолучитьСоотвПолей();
	Для Каждого эл Из СтруктураПолей Цикл
		ИмяПоляЗвонка  = СоотвПолей.Получить( нрег(эл.Ключ) ); 
		
		Если ИмяПоляЗвонка = Неопределено Тогда // нет соответствия для такого поля - полю в регистре!
			Продолжить;    
			
		ИначеЕсли ИмяПоляЗвонка = "Входящий" Тогда  // в Булево
			значПоляЗвонка = (эл.Значение = "in");
			
		ИначеЕсли ИмяПоляЗвонка = "Канал" и лев(эл.Значение,1)="{"  Тогда // нет канала!
			 значПоляЗвонка = "";
			  
		ИначеЕсли стрНайти(ИмяПоляЗвонка, "Номер") Тогда // число в строку!
			значПоляЗвонка = Формат(эл.Значение, "ЧГ=0");
			
		ИначеЕсли ИмяПоляЗвонка = "Период" И ТипЗнч(эл.Значение) = тип("Строка") Тогда // в Дату и Время!
			СтрокаДата = эл.Значение;
			
			Если сред(СтрокаДата, 3, 1) = "." Тогда  // "нормальная" дата "02.02.2022T12:12:12"
				СтрокаДата = СтрЗаменить(СтрокаДата, "T", "");
				значПоляЗвонка = Дата(СтрокаДата);
			Иначе			
				Для i = 0 По МассивЗаменДаты.Количество() - 1 Цикл
				   СтрокаДата = СтрЗаменить(СтрокаДата, МассивЗаменДаты[i], ""); 
				КонецЦикла;
				значПоляЗвонка = Дата(СтрокаДата);
			КонецЕсли;

		ИначеЕсли ИмяПоляЗвонка = "ИдСессии" И ТипЗнч(эл.Значение) = тип("Строка") Тогда // в Число!
			значПоляЗвонка = число(эл.Значение);
			
		Иначе
			значПоляЗвонка = эл.Значение;
		КонецЕсли;	
		
		стрПолейЗвонков.Вставить(ИмяПоляЗвонка, значПоляЗвонка);
	КонецЦикла;	 
	
	Возврат стрПолейЗвонков;
КонецФункции

#КонецОбласти

// Внутренние методы
#Область СлужебныеПроцедурыИФункции

// Функция - Получить соответствие полей
// поля уведомлений POST-запроса от UIScom по звонкам - сопоставляем с полями Рег.Св.ИсторияЗвонков
//
// ПОЛЯ УВЕДОМЛЕНИЙ от UIScom описаны на странице https://help.synergycrm.ru/integratsiya-s-uis 
// подробный API по работе со звонками описан на странице https://comagic.github.io/call-api/
// (здесь НЕ используется!)
//  
// ПРИМЕР:
// {
// "Start_time":"2016-07-24 23:59:07.863",
// "notification_name":"Входящий звонок",
// "direction":"in",
// "call_session_id":187020303,
// "extension_phone_number":5648,
//
// "virtual_phone_number":74950000001,
// "called_phone_number":79260000002,
// "calling_phone_number":79260000001,
//
// "employee_phone_number":79260000000,
// "total_time_duration":60,
// "wait_time_duration":15,
//
// "finish_time":"2016-05-06 12:33:33.605",
// "finish_reason":"no_active_scenario",
//
// "is_lost":true,
// "lost_reason":"Не найден активный сценарий",
//
// "full_record_file_link":"https://app.uiscom.ru/system/media/talk/170346666/full/c39e617f91f071ec4c6f8d797de35c26/",
// "wav_call_records":"file.wav",
//
// "call_source":"call_tracking",
// "scenario_name":"Обзвон по сценарию"
//
// }
// 
// Возвращаемое значение:
//  Соответствие - название поля UIScom (в нижнем регистре) или  сопоставляются ВСЕ поля этого регистра сведений!
//
Функция ПолучитьСоотвПолей() 
	
	соотв = Новый Соответствие;
	
	// --------- обязательные Измерения! -----------------        
	соотв.Вставить("notification_name",    "ИмяСобытия"); // "Входящий звонок"
	соотв.Вставить("start_time", "ВремяНачала"); // строка "как есть" 
	
	соотв.Вставить("direction", 		"Входящий"); // Булево
	соотв.Вставить("call_session_id",   "ИдСессии"); // Число
	соотв.Вставить("extension_phone_number", "Канал"); // Внутренний номер сотрудника
	
	соотв.Вставить("virtual_phone_number", "Номер"); 			// Строка - Виртуальный номер сотрудника
	соотв.Вставить("called_phone_number",  "ЗвонящийНомер");    // Кто звонит
	соотв.Вставить("calling_phone_number", "ВызываемыйНомер");  // Кому звонят
	
	соотв.Вставить("total_time_duration", "Длительность");
	соотв.Вставить("wait_time_duration",  "ВремяОжидания");
	
	// --------- поля Centrifugo -----------------------------------	
	соотв.Вставить("send", "Отправлен"); 
	
	// --------------------- Запись звонка ------------------------	
	соотв.Вставить("full_record_file_link", "СсылкаНаЗапись");
	
	// -------- ВЕСЬ ТЕКСТ ТЕЛА ЗАПРОСА ---------------
	соотв.Вставить("body", "ТелоЗапроса");      
	
	Возврат соотв;
КонецФункции

#КонецОбласти
