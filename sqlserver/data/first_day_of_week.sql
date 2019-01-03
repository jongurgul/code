--http://jongurgul.com/blog/first-day-week/
DECLARE @dt DATETIME
SET @dt = DATEADD(DAY,0,DATEDIFF(DAY,0,CURRENT_TIMESTAMP))   
SELECT @dt [dt]
,DATEADD(DAY,-DATEPART(dw,@dt)+1,@dt) [First Day Of Week (SET DATEFIRST X Dependent)]
,DATEADD(DAY,-((@@DATEFIRST+DATEPART(dw,DATEADD(DAY,-2,@dt)))%7),@dt) [First Day Of Week (Monday)]
,DATEADD(DAY,-((@@DATEFIRST+DATEPART(dw,DATEADD(DAY,-3,@dt)))%7),@dt) [First Day Of Week (Tuesday)]
,DATEADD(DAY,-((@@DATEFIRST+DATEPART(dw,DATEADD(DAY,-4,@dt)))%7),@dt) [First Day Of Week (Wednesday)]
,DATEADD(DAY,-((@@DATEFIRST+DATEPART(dw,DATEADD(DAY,-5,@dt)))%7),@dt) [First Day Of Week (Thursday)]
,DATEADD(DAY,-((@@DATEFIRST+DATEPART(dw,DATEADD(DAY,-6,@dt)))%7),@dt) [First Day Of Week (Friday)]
,DATEADD(DAY,-((@@DATEFIRST+DATEPART(dw,@dt))%7),@dt) [First Day Of Week (Saturday)]
,DATEADD(DAY,-((@@DATEFIRST+DATEPART(dw,DATEADD(DAY,-1,@dt)))%7),@dt) [First Day Of Week (Sunday)]