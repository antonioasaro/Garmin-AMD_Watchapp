using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class AMDApp extends App.AppBase {

    function initialize() {
        Sys.println("Antonio - initalizing AppBase");
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new AMDView(), new AMDDelegate() ];
    }

}
