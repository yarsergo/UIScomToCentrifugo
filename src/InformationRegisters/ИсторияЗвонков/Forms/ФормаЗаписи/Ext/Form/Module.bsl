﻿
&НаКлиенте
Процедура СсылкаНаЗаписьОткрытие(Элемент, СтандартнаяОбработка)
	
	Если СтрНайти(Запись.СсылкаНаЗапись, "http") > 0 Тогда 
		//СтандартнаяОбработка = Ложь;	
		//Попытка  // Доступен, начиная с версии 8.3.18.
		//	Результат = ЗапуститьПриложениеАсинх( Запись.СсылкаНаЗапись ); // открывает браузер по-умолчанию и открывает файл
		//Исключение
		//	Сообщение = Новый СообщениеПользователю;
		//	Сообщение.Текст = "НЕ удалось открыть запись по ссылке: " + Запись.СсылкаНаЗапись + "
		//	| " + ОписаниеОшибки();
		//	Сообщение.Сообщить(); 
		//КонецПопытки;	
	КонецЕсли;	
	
КонецПроцедуры

// Функция - Послать сервер
//
// Параметры:
//  стр	 - Структура - структура полей для отправки Centrifugo 
// 
// Возвращаемое значение:
//  булево - признак удачной отправки
//
&НаСервере
Функция ПослатьСервер(стр, ВесьЗапрос = Ложь) 
	
	стр.Канал = ?(стр.Канал = "", CentrifugoСервер.ПолучитьКаналПоНомеру(стр.Номер), стр.Канал); 

	Успешно = CentrifugoСервер.ПослатьСообщениеНаКанал( стр, ВесьЗапрос );
 
	стр.Отправлен = Успешно;

	Возврат Успешно;
КонецФункции

&НаКлиенте
Процедура Послать(Команда)  
	стрЗвонка = Новый Структура("Номер, Входящий, ИмяСобытия, Канал, ЗвонящийНомер, ВызываемыйНомер, ТелоЗапроса, Отправлен",
									"", Истина, 		"", 	"",				"",				 "", 		"",		Ложь);
	ЗаполнитьЗначенияСвойств( стрЗвонка, Запись ); 

	ВесьЗапрос = ( стрЗвонка.ИмяСобытия = "Завершение звонка" );  // 20.07.2022
	Успешно = ПослатьСервер(стрЗвонка, ВесьЗапрос);  
	Запись.Отправлен = Успешно;
	
	Сообщение = Новый СообщениеПользователю;
	Сообщение.Текст = ?(Успешно, "УСПЕШНО ", "НЕ") 
						+ " отправлен в Канал: " + Запись.Канал+ "
						|Text: " + ?(ВесьЗапрос, стрЗвонка.ТелоЗапроса, стрЗвонка.ЗвонящийНомер); 
	Сообщение.Поле = "Канал"; 
	Сообщение.Сообщить();
	
КонецПроцедуры
