$Site = "https://yandex.ru/pogoda/vladivostok/details"
$HttpContent = Invoke-WebRequest -Uri $Site

$weather = @{}

$day_names = $HttpContent.ParsedHtml.getElementsByTagName("span") | Where-Object { $_.className -eq "forecast-details__day-name" }  | % { $_.innerText }
$day_number_value = $HttpContent.ParsedHtml.getElementsByTagName("strong") | Where-Object { $_.className -eq "forecast-details__day-number" }  | % { $_.innerText }
$day_month_value = $HttpContent.ParsedHtml.getElementsByTagName("span") | Where-Object { $_.className -eq "forecast-details__day-month" }  | % { $_.innerText }
$parts_of_the_day = $HttpContent.ParsedHtml.getElementsByTagName("div") | Where-Object { $_.className -eq "weather-table__daypart" }  | % { $_.innerText }


$temp_value = $HttpContent.ParsedHtml.getElementsByTagName("span") | Where-Object { $_.className -eq "temp__value" }  | % { $_.innerText + "°"}

$weather_conditions = $HttpContent.ParsedHtml.getElementsByTagName("td") | Where-Object { $_.className -eq "weather-table__body-cell weather-table__body-cell_type_condition" }  | % { $_.innerText}


$day_names.Count
$day_number_value.Count
$day_month_value.Count
$parts_of_the_day.Count
$temp_value.Count
$weather_conditions.Count

$temp = @{}
$j = 0
$k = 0

for ($i = 0; $i -lt 9; $i++) { 
$day_names[$i]
    $parts_of_the_day[$j]
                    $($temp_value[$k])
                    $($temp_value[$($k+1)])
                    $($temp_value[$($k+2)])
    $parts_of_the_day[$($j+1)]
                    $($temp_value[$($k+3)])
                    $($temp_value[$($k+4)])
                    $($temp_value[$($k+5)])
    $parts_of_the_day[$($j+2)]
                    $($temp_value[$($k+6)])
                    $($temp_value[$($k+7)])
                    $($temp_value[$($k+8)])    
    $parts_of_the_day[$($j+3)]
                    $($temp_value[$($k+9)])
                    $($temp_value[$($k+10)])
                    $($temp_value[$($k+11)])
<#
    $temp."$($day_names[$i])" = @{
                                $parts_of_the_day[$j] = @{
                                                            "Мин" =       "$($temp_value[$k])";
                                                            "Макс" =      "$($temp_value[$($k+1)])";
                                                            "Ощущается" = "$($temp_value[$($k+2)])";
                                                         };
                                $parts_of_the_day[$($j+1)] = @{
                                                            "Мин" =       "$($temp_value[$($k+3)])";
                                                            "Макс" =      "$($temp_value[$($k+4)])";
                                                            "Ощущается" = "$($temp_value[$($k+5)])";
                                                              };
                                $parts_of_the_day[$($j+2)] = @{
                                                            "Мин" =       "$($temp_value[$($k+6)])";
                                                            "Макс" =      "$($temp_value[$($k+7)])";
                                                            "Ощущается" = "$($temp_value[$($k+8)])";                                
                                                              };
                                $parts_of_the_day[$($j+3)] = @{
                                                            "Мин" =       "$($temp_value[$($k+9)])";
                                                            "Макс" =      "$($temp_value[$($k+10)])";
                                                            "Ощущается" = "$($temp_value[$($k+11)])";                                                                
                                                              }
                              } #>
    $j += 4; $k += 12;

}

$temp.понедельник.днём.Ощущается

$name_value = $HttpContent.ParsedHtml.getElementsByTagName("div") | Where-Object { $_.className -eq "weather-table__value" }  | % { $_.innerText }

$wind_speed = $HttpContent.ParsedHtml.getElementsByTagName("span") | Where-Object { $_.className -eq "wind-speed" }  | % { $_.innerText }


#Восход-Закат
function Get-SunriseSunset {
    $sunrise_sunset = @{}
        $sunrise_sunset_Name = $($HttpContent.ParsedHtml.getElementsByTagName("span") | Where-Object { $_.className -eq "sunrise-sunset__text" }  | % { $_.innerText })
        $sunrise_sunset_Value = $($HttpContent.ParsedHtml.getElementsByTagName("dd") | Where-Object { $_.className -eq "sunrise-sunset__value" } | % { $_.innerText })
        if ($sunrise_sunset_Name.Count -eq $sunrise_sunset_Value.Count)
            {
                $step = 0
                foreach ($day_name in $day_names)
                {
                    $sunrise_sunset."$($day_name)"= @{ 
                                                       $sunrise_sunset_name[$step] = $sunrise_sunset_Value[$step] ; 
                                                       $sunrise_sunset_name[$($step+1)] = $sunrise_sunset_Value[$($step+1)];
                                                       $sunrise_sunset_name[$($step+2)] = $sunrise_sunset_Value[$($step+2)]
                                                     }
                $step += 3
                }
            }        
    return $sunrise_sunset
}
#Фаза луны
function Get-MoonPhase{
$moon = @{}
    $moon_data = $HttpContent.ParsedHtml.getElementsByTagName("span") | Where-Object { $_.className -eq "forecast-details__moon-title" }  | % { $_.innerText }
    $i=0; $day_names | %{ $moon."$($_)"= $moon_data[$i]; $i++}
return $moon
}

