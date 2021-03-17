#Меню

Write-Warning -Message "Скрининг устанавливается на все диски в системе!`n`n`n"
Write-Host "1. Установить скрининг по маске *.* на всех серверах из servers.txt" -ForegroundColor Red -BackgroundColor Black
Write-Host "2. Установить скрининг по произвольной маске на всех серверах из servers.txt Пример для нескольких типов: *.wncry|*.wnry" -ForegroundColor Red -BackgroundColor Black
Write-Host "3. Удалить установленный скриптом скрининг" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "4. Exit" -ForegroundColor Green -BackgroundColor Black
Write-Host


$choice = Read-Host "Выберите нужный пункт"

#запрашиваем данные уз с нужными правами
[System.Management.Automation.PSCredential]$Credential = Get-Credential 


#указываем, откуда брать список серверов. TODO: реализовать получение списка из OU в AD
$path_servers = "servers.txt"

Switch($choice){   
  1{                                 
	Get-Content servers.txt | %{ 
				
        $connect = Invoke-Command -ComputerName $_ -ArgumentList "*.*" -Credential $Credential -ScriptBlock {
        		
			$Mask = $args[0]
        	#Задаем имя групп и скрининга
        	$Name = "MegaScreening-Alarm"
 
			#Получаем список дисков
        	$drives = Get-WmiObject -Class Win32_Volume -Filter "DriveType='3'" | ?{ $_.Name -notmatch [regex]::Escape("\\?") } | Sort Name | Select -ExpandProperty Name -Unique


			#Проверяем наличие созданного скрининга
			$existing_screens = Filescrn f l /Filegroup:$Name
	        
			if ($existing_screens -match "not found"){
 
				#Создаем файл группу по маске *.*
        		Filescrn Filegroup Add /Filegroup:$Name /Members:$Mask | findstr successfully 
        
				#Создаем шаблон по фаилгруппе МегаСкрининг 
        		Filescrn Template Add /Template:$Name /Add-Filegroup:$Name /Type:Active | findstr successfully
        
				#Создаем скрининг по шаблону  
        		foreach ($drive in $drives) { Filescrn Screen Add /Path:$drive /SourceTemplate:$Name | findstr successfully }
			 }


			else {
					Filescrn Filegroup modify /Filegroup:$Name /Members:$Mask | findstr successfully
					Filescrn Template Add /Template:$Name /Add-Filegroup:$Name /Type:Active | findstr successfully
					foreach ($drive in $drives) { 
						Filescrn Screen Add /Path:$drive /SourceTemplate:$Name | findstr successfully 
					}
			}		
        
        }; Write-Host -ForegroundColor DarkYellow $_ $connect
      }
  }

  2{    
    	#Задаем маску для создания файл группы 
		$masks = Read-Host "Введите маску. Пример для нескольких типов: *.wncry|*.wnry"
    
	Get-Content $path_servers | %{
        $connect = Invoke-Command -ComputerName $_ -ArgumentList $masks -Credential $Credential -ScriptBlock {
				
			$Mask = $args[0]
        	#Задаем имя групп и скрининга
        	$Name = "Screening-Alarm"
 
			#Получаем список дисков
        	$drives = Get-WmiObject -Class Win32_Volume -Filter "DriveType='3'" | ?{ $_.Name -notmatch [regex]::Escape("\\?") } | Sort Name | Select -ExpandProperty Name -Unique


			#Проверяем наличие созданного скрининга
			$existing_screens = Filescrn f l /Filegroup:$Name
	        
			if ($existing_screens -match "not found"){
 
				#Создаем файл группу по маске *.*
        		Filescrn Filegroup Add /Filegroup:$Name /Members:$Mask | findstr successfully 
        
				#Создаем шаблон по фаилгруппе МегаСкрининг 
        		Filescrn Template Add /Template:$Name /Add-Filegroup:$Name /Type:Active | findstr successfully
        
				#Создаем скрининг по шаблону  
        		foreach ($drive in $drives) { Filescrn Screen Add /Path:$drive /SourceTemplate:$Name | findstr successfully }
			 }

			#Если есть, модифицируем
			else {
					Filescrn Filegroup modify /Filegroup:$Name /Members:$Mask | findstr successfully
					Filescrn Template Add /Template:$Name /Add-Filegroup:$Name /Type:Active | findstr successfully
					foreach ($drive in $drives) { 
						Filescrn Screen Add /Path:$drive /SourceTemplate:$Name | findstr successfully 
					}
        
        }; Write-Host -ForegroundColor DarkYellow $_ $connectt
    }
  }
}

  3{    

        Get-Content $path_servers | %{
        $connect = Invoke-Command -ComputerName $_ -Credential $Credential -ScriptBlock {
		
		
        $drives = Get-WmiObject -Class Win32_Volume -Filter "DriveType='3'" | ?{ $_.Name -notmatch [regex]::Escape("\\?") } | Sort Name | Select -ExpandProperty Name -Unique
        
		$Name = "MegaScreening-Alarm"
        
		#Удаляем 
        Filescrn Filegroup Delete /Filegroup:$Name /Quiet | findstr successfully
        Filescrn Template Delete /Template:$Name /Quiet | findstr successfully
        
		foreach ($drive in $drives) { Filescrn Screen Delete /Path:$drive /Quiet | findstr successfully }
        
        }; Write-Host -ForegroundColor DarkYellow $_ $connect
    }

    }


  4{Write-Host "Exit"; exit}
   
  default {Write-Host "Wrong choice, try again." -ForegroundColor Red}
}
