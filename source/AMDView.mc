using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer as Timer;
using Toybox.Communications as Comm;
using Toybox.Attention as Att;
using Toybox.Position as Pos;


class AMDView extends Ui.View {
	hidden const MASTER_TIMER_SECS = 60;
	hidden const MASTER_TIMER_TRIG = (15 * 60) / MASTER_TIMER_SECS;
	hidden const MASTER_TIMER_UPDATE_WEATHER = 1;
	hidden const MASTER_TIMER_UPDATE_STOCK   = 2;

    hidden var alignTimer;
    hidden var masterTimer;
    hidden var masterTimerTics = 0;
    hidden var skipWeather = 0;
    hidden var forceStock = 1;
    hidden var wtstatusBitmap;
    hidden var BTstatusBitmap;
    
    hidden var gpsLat = 40.71;		// New York
	hidden var gpsLon = -74.00;

    function onMasterTimer() {
        requestUpdate();

        if (masterTimerTics == MASTER_TIMER_UPDATE_WEATHER) { 
            if (skipWeather == 0) { makeWeatherRequest(); skipWeather = 1; } else { skipWeather = 0; }
        } 
        if (masterTimerTics == MASTER_TIMER_UPDATE_STOCK  ) { 
    	    var now = Time.now();
            var info = Calendar.info(now, Time.FORMAT_SHORT);
            var day  = info.day_of_week;
            var hour = info.hour;
            if ((forceStock == 1) | ((hour > 8) & (hour < (6 + 12)) & (day > 1) & (day < 7))) { makeStockRequest(); forceStock = 0; }  
        } 
        masterTimerTics = (masterTimerTics + 1) % MASTER_TIMER_TRIG;
        
    }
 
    function onAlignTimer() {
        masterTimer = new Timer.Timer();
        masterTimer.start(method(:onMasterTimer), MASTER_TIMER_SECS * 1000, true);
    }

    function initialize() {
        Sys.println("Antonio - initalizing AMDView");
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        Sys.println("Antonio - onLayout");
        BTstatusBitmap = Ui.loadResource(Rez.Drawables.ConnectIcon);
        wtstatusBitmap = Ui.loadResource(Rez.Drawables.BlankIcon);

		var curLoc = Activity.getActivityInfo().currentLocation;
		if (curLoc != null) {
			gpsLat= curLoc.toDegrees()[0].toFloat();
			gpsLon = curLoc.toDegrees()[1].toFloat();
		}

        var clockTime = Sys.getClockTime();
    	var sec = clockTime.sec; 
        alignTimer = new Timer.Timer();
        alignTimer.start(method(:onAlignTimer), (60 - sec) * 1000, false);
        setLayout(Rez.Layouts.MainLayout(dc));
    }
   
    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        Sys.println("Antonio - onUpdate");
        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);
        var dateString = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
        var dateView = View.findDrawableById("id_date");
        dateView.setText(dateString);
            
        var clockTime = Sys.getClockTime();
        var hour = clockTime.hour; 
        if (hour > 12) { hour = hour - 12; }
        var timeString = Lang.format("$1$:$2$", [hour, clockTime.min.format("%02d")]);
        var timeView = View.findDrawableById("id_time");
        timeView.setText(timeString);    
    
        var devSettings = Sys.getDeviceSettings();
        if (devSettings.phoneConnected) { 
	 		BTstatusBitmap = Ui.loadResource(Rez.Drawables.ConnectIcon);
        } else {
	 		BTstatusBitmap = Ui.loadResource(Rez.Drawables.DisconnectIcon);
	 	}

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var btstatusView = View.findDrawableById("id_btstatus");
        var wtstatusView = View.findDrawableById("id_wtstatus");
        dc.drawBitmap(btstatusView.locX, btstatusView.locY, BTstatusBitmap);
        dc.drawBitmap(wtstatusView.locX, wtstatusView.locY, wtstatusBitmap);
        
        var stats = Sys.getSystemStats(); 
        var battery = stats.battery;
        dc.setColor(0xBBBBBB, Gfx.COLOR_TRANSPARENT);
        if (battery < 100) { dc.drawText(22, 102, Gfx.FONT_SYSTEM_XTINY, battery.format("%d") + "%", Gfx.TEXT_JUSTIFY_CENTER); }
        if (battery <= 25) { dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT); }
        dc.fillRectangle(15, 76, 9, 3);
        dc.fillRectangle(13, 79, 14, 25);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(15, 81, 10, (20 * (100 - battery)) / 100);
   	}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // Receive temperature data from the web
    function onTempReceive(responseCode, data) {
        Sys.println("Antonio - onTempReceive");
        var tempView = View.findDrawableById("id_temp");
        if (responseCode == 200) {
        	Sys.println("Weather response data: " + data);
           	var main = data["main"]; var temperature = (main["temp"] - 273.15); 
           	var temp = temperature.format("%d");
           	var degree = "°C";
        	tempView.setText(temp + degree);
        	
           	var weather = data["weather"]; var rsp = weather[0]; var weatherId = rsp["id"];
          	if (weatherId < 600) {
	 			wtstatusBitmap = Ui.loadResource(Rez.Drawables.RainIcon);
          	} else if (weatherId < 700) {
	 			wtstatusBitmap = Ui.loadResource(Rez.Drawables.SnowIcon);
	 		} else if (weatherId < 800) { 
	 			wtstatusBitmap = Ui.loadResource(Rez.Drawables.MistIcon);
          	} else if (weatherId < 900) {
		        var clockTime = Sys.getClockTime();
        		var hour = clockTime.hour; 
	 			if ((hour < 7) | ( hour > (8 + 12))) { 
		 			wtstatusBitmap = Ui.loadResource(Rez.Drawables.MoonIcon);
	 			} else if (weatherId < 803) {
		 			wtstatusBitmap = Ui.loadResource(Rez.Drawables.SunIcon);
	 		    } else {
		 			wtstatusBitmap = Ui.loadResource(Rez.Drawables.PartlyIcon);
		 		}
          	} else {
	 			wtstatusBitmap = Ui.loadResource(Rez.Drawables.CloudIcon);
          	}
        } else {
           	Sys.println("Failed to load temperatures\nError: " + responseCode.toString());
           	tempView.setColor(Gfx.COLOR_RED);
        }
        requestUpdate();
    }
    
    // Receive the stock price from the web
    function onStockReceive(responseCode, data) {
        Sys.println("Antonio - onStockReceive");
        var stockView = View.findDrawableById("id_stock");
        if (responseCode == 200) {
        	Sys.println("Stock response data: " + data);
           	var price = data["price"]; 
        	stockView.setText("$" + price);
       		stockView.setColor(Gfx.COLOR_WHITE);
        } else {
           	Sys.println("Failed to load stocks\nError: " + responseCode.toString());
       		stockView.setColor(Gfx.COLOR_RED);
        }
        requestUpdate();
    }

    // Make the weather web request
    function makeWeatherRequest() {
        Sys.println("Antonio - makeWeatherRequest");
        Sys.println("Antonio - gpsCoords: " + gpsLat + ", " + gpsLon);
        Comm.makeWebRequest("http://api.openweathermap.org/data/2.5/weather", {"lat" => gpsLat, "lon" => gpsLon, "appid" => "eaceb3c6dcff48730ddad91fe09d8f4f"}, {}, method(:onTempReceive));
    }

    // Make the stock web request
    function makeStockRequest() {
        Sys.println("Antonio - makeStockRequest");
		Comm.makeWebRequest("http://www.asarotools.com/stockprice.php", {"stock" => "NYSE:AMD"}, {}, method(:onStockReceive));
    }

}
