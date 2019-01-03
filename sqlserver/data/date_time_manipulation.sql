--http://jongurgul.com/blog/time-calculations-rounding-time-0000-minute/
DECLARE @dt DATETIME
SET @dt = CURRENT_TIMESTAMP

--Removing the time portion / zero the time
SELECT @dt [dt]
,DATEADD(DAY,-1,DATEDIFF(DAY,0,@dt))                 [YesterdayZeroHour]  	
,DATEADD(DAY,0,DATEDIFF(DAY,0,@dt))                  [TodayZeroHour]  
,DATEADD(DAY,1,DATEDIFF(DAY,0,@dt))                  [TomorrowZeroHour]  
,CAST(DATEADD(DAY,-1,CAST(@dt AS DATE)) AS DATETIME) [YesterdayZeroHour] --USING DATE TYPE 2008+
,CAST(CAST(@dt AS DATE) AS DATETIME)                 [TodayZeroHour]	 --USING DATE TYPE 2008+
,CAST(DATEADD(DAY,1,CAST(@dt AS DATE)) AS DATETIME)  [TomorrowZeroHour]  --USING DATE TYPE 2008+

--Round fractions time down to different boundaries
SELECT @dt [dt]
,DATEADD(n,(DATEDIFF(n,0,@dt)/5*5),0)   [Rounded Down 05 Min]
,DATEADD(n,(DATEDIFF(n,0,@dt)/6*6),0)   [Rounded Down 06 Min]
,DATEADD(n,(DATEDIFF(n,0,@dt)/10*10),0) [Rounded Down 10 Min]
,DATEADD(n,(DATEDIFF(n,0,@dt)/15*15),0) [Rounded Down 15 Min]
,DATEADD(n,(DATEDIFF(n,0,@dt)/20*20),0) [Rounded Down 20 Min]
,DATEADD(n,(DATEDIFF(n,0,@dt)/30*30),0) [Rounded Down 30 Min]

--Round fractions time up to different boundaries exact parts not rounded up e.g. 5:05 with 05 Mins left as 5:05
SELECT @dt [dt]
,DATEADD(n,DATEDIFF(n,0,@dt)+5-COALESCE(NULLIF(DATEDIFF(n,0,@dt)%5,0),5),0)    [Rounded Up 05 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+6-COALESCE(NULLIF(DATEDIFF(n,0,@dt)%6,0),6),0)    [Rounded Up 06 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+10-COALESCE(NULLIF(DATEDIFF(n,0,@dt)%10,0),10),0) [Rounded Up 10 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+15-COALESCE(NULLIF(DATEDIFF(n,0,@dt)%15,0),15),0) [Rounded Up 15 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+20-COALESCE(NULLIF(DATEDIFF(n,0,@dt)%20,0),20),0) [Rounded Up 20 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+30-COALESCE(NULLIF(DATEDIFF(n,0,@dt)%30,0),30),0) [Rounded Up 30 Min]

--Always Round time up e.g. 5:05 with 05 Mins rounded up to 5:10
SELECT @dt [dt]
,DATEADD(n,DATEDIFF(n,0,@dt)+(5-(DATEDIFF(n,0,@dt)%5)),0)   [Rounded Up 05 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+(6-(DATEDIFF(n,0,@dt)%6)),0)   [Rounded Up 06 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+(10-(DATEDIFF(n,0,@dt)%10)),0) [Rounded Up 10 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+(15-(DATEDIFF(n,0,@dt)%15)),0) [Rounded Up 15 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+(20-(DATEDIFF(n,0,@dt)%20)),0) [Rounded Up 20 Min]
,DATEADD(n,DATEDIFF(n,0,@dt)+(30-(DATEDIFF(n,0,@dt)%30)),0) [Rounded Up 30 Min]