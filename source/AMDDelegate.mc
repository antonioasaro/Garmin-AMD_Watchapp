using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class AMDDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        Sys.println("Antonio - initalizing AMDDelegate");
        BehaviorDelegate.initialize();
    }

    function onMenu() {
    	Sys.println("Antonio - onMenu");
        Ui.pushView(new Rez.Menus.MainMenu(), new AMDMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }

}