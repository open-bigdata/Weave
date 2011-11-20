/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.text.Font;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.utils.StringUtil;
	
	import ru.etcs.utils.FontLoader;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.core.weave_internal;
	import weave.data.CSVParser;
	import weave.resources.fonts.EmbeddedFonts;
	import weave.utils.CSSUtils;
	import weave.utils.DebugUtils;
	import weave.utils.NumberUtils;
	import weave.visualization.layers.InteractionController;
	import weave.visualization.layers.LinkableEventListener;

	use namespace weave_internal;
	
	/**
	 * A list of global settings for a Weave instance.
	 */
	public class WeaveProperties implements ILinkableObject
	{
		[Embed(source="/weave/weave_version.txt", mimeType="application/octet-stream")]
		private static const WeaveVersion:Class;
		
		public const version:LinkableString = new LinkableString(); // Weave version
		
		public function WeaveProperties()
		{
			version.value = StringUtil.trim((new WeaveVersion() as ByteArray).toString());
			version.lock(); // don't allow changing the version
			
			// register all properties as children of this object
			for each (var propertyName:String in (WeaveAPI.SessionManager as SessionManager).getLinkablePropertyNames(this))
				registerLinkableChild(this, this[propertyName] as ILinkableObject);
			
			enableWeaveFonts.addGroupedCallback(this,loadEmbeddedFonts,true);

			// handle dynamic changes to the session state that change what CSS file to use
			cssStyleSheetName.addGroupedCallback(
				this,
				function():void
				{
					CSSUtils.loadStyleSheet(cssStyleSheetName.value);
				}
			);

		}
		
		private function loadEmbeddedFonts():void
		{
			if(Weave.properties.enableWeaveFonts.value)
			{
				fontLoader.autoRegister = true;
				fontLoader.addEventListener(Event.COMPLETE,weaveFontsLoaded);
				fontLoader.addEventListener(IOErrorEvent.IO_ERROR,handleLoaderErrorEvent);
				fontLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleLoaderErrorEvent);
				fontLoader.load(new URLRequest("WeaveFonts.swf"));
			}			
		}
		
		private var fontLoader:FontLoader = new FontLoader();
		
		public static const embeddedFonts:ArrayCollection = new ArrayCollection([EmbeddedFonts.SophiaNubian]);
		private function weaveFontsLoaded(event:Event):void
		{
			var fonts:Array = fontLoader.fonts;
			
			for each (var font:Font in fonts)
			{
				embeddedFonts.addItem(font.fontName);
			}
			
		}
		
		private function handleLoaderErrorEvent(event:Event):void
		{
			//DO Nothing
		}
		
		public static const DEFAULT_FONT_FAMILY:String = EmbeddedFonts.SophiaNubian;
		public static const DEFAULT_FONT_SIZE:Number = 10;
		public static const DEFAULT_AXIS_FONT_SIZE:Number = 11;
		public static const DEFAULT_BACKGROUND_COLOR:Number = 0xCCCCCC;
		
		private static const WIKIPEDIA_URL:String = "Wikipedia|http://en.wikipedia.org/wiki/Special:Search?search=";
		private static const GOOGLE_URL:String = "Google|http://www.google.com/search?q=";
		private static const GOOGLE_MAPS_URL:String = "Google Maps|http://maps.google.com/maps?t=h&q=";
		private static const GOOGLE_IMAGES_URL:String = "Google Images|http://images.google.com/images?q=";
		
		private function verifyFontSize(value:Number):Boolean { return value > 2; }
		private function verifyAlpha(value:Number):Boolean { return 0 <= value && value <= 1; }
		private function verifyWindowSnapGridSize(value:String):Boolean
		{
			if (!NumberUtils.verifyNumberOrPercentage(value))
				return false;
			if (value && value.substr(-1) == '%')
				return StandardLib.asNumber(value.substr(0, -1)) > 0;
			return StandardLib.asNumber(value) >= 1;
		}
		private function verifyMaxTooltipRecordsShown(value:Number):Boolean { return 0 <= value && value <= 20; }

		public const dataInfoURL:LinkableString = new LinkableString(); // file to link to for metadata information
		
//		public const showViewBar:LinkableBoolean = new LinkableBoolean(false); // show/hide Views TabBar
		public const windowSnapGridSize:LinkableString = new LinkableString("1%", verifyWindowSnapGridSize); // window snap grid size in pixels
		
		public const cssStyleSheetName:LinkableString = new LinkableString("weaveStyle.css"); // CSS Style Sheet Name/URL
		public const backgroundColor:LinkableNumber = new LinkableNumber(DEFAULT_BACKGROUND_COLOR, isFinite);
		
		public const enableWeaveFonts:LinkableBoolean = new LinkableBoolean(true);
		
		
		// enable/disable advanced features
		public const enableMouseWheel:LinkableBoolean = new LinkableBoolean(true);
		public const enableDynamicTools:LinkableBoolean = new LinkableBoolean(true); // move/resize/add/remove/close tools
		
		public const showColorController:LinkableBoolean = new LinkableBoolean(true); // Show Color Controller option tools menu
		public const showProbeToolTipEditor:LinkableBoolean = new LinkableBoolean(true);  // Show Probe Tool Tip Editor tools menu
		public const showEquationEditor:LinkableBoolean = new LinkableBoolean(true); // Show Equation Editor option tools menu
		public const showAttributeSelector:LinkableBoolean = new LinkableBoolean(true); // Show Attribute Selector tools menu
		public const enableNewUserWizard:LinkableBoolean = new LinkableBoolean(true); // Add New User Wizard option tools menu		
		
		public const enableAddAttributeMenuTool:LinkableBoolean = new LinkableBoolean(true); // Add Attribute Menu Tool option tools menu
		public const enableAddBarChart:LinkableBoolean = new LinkableBoolean(true); // Add Bar Chart option tools menu
		public const enableAddCollaborationTool:LinkableBoolean = new LinkableBoolean(false);
		public const enableAddColorLegend:LinkableBoolean = new LinkableBoolean(true); // Add Color legend Tool option tools menu		
		public const enableAddColormapHistogram:LinkableBoolean = new LinkableBoolean(true); // Add Colormap Histogram option tools menu
		public const enableAddCompoundRadViz:LinkableBoolean = new LinkableBoolean(true); // Add CompoundRadViz option tools menu
		public const enableAddCustomTool:LinkableBoolean = new LinkableBoolean(true);
		public const enableAddDataFilter:LinkableBoolean = new LinkableBoolean(true);
		public const enableAddDataTable:LinkableBoolean = new LinkableBoolean(true); // Add Data Table option tools menu
		public const enableAddGaugeTool:LinkableBoolean = new LinkableBoolean(true); // Add Gauge Tool option tools menu
		public const enableAddHistogram:LinkableBoolean = new LinkableBoolean(true); // Add Histogram option tools menu
		public const enableAdd2DHistogram:LinkableBoolean = new LinkableBoolean(true); // Add 2D Histogram option tools menu
		public const enableAddGraphTool:LinkableBoolean = new LinkableBoolean(true); // Add Graph Tool option tools menu
		public const enableAddLineChart:LinkableBoolean = new LinkableBoolean(true); // Add Line Chart option tools menu
		public const enableAddDimensionSliderTool:LinkableBoolean = new LinkableBoolean(true); // Add Dimension Slider Tool option tools menu		
		public const enableAddMap:LinkableBoolean = new LinkableBoolean(true); // Add Map option tools menu
		public const enableAddPieChart:LinkableBoolean = new LinkableBoolean(true); // Add Pie Chart option tools menu
		public const enableAddPieChartHistogram:LinkableBoolean = new LinkableBoolean(true); // Add Pie Chart option tools menu
		public const enableAddRadViz:LinkableBoolean = new LinkableBoolean(true); // Add RadViz option tools menu		
		public const enableAddRamachandranPlot:LinkableBoolean = new LinkableBoolean(false); // Add RamachandranPlot option tools menu		
		public const enableAddRScriptEditor:LinkableBoolean = new LinkableBoolean(true); // Add R Script Editor option tools menu		
		public const enableAddScatterplot:LinkableBoolean = new LinkableBoolean(true); // Add Scatterplot option tools menu
		public const enableAddThermometerTool:LinkableBoolean = new LinkableBoolean(true); // Add Thermometer Tool option tools menu
		public const enableAddTimeSliderTool:LinkableBoolean = new LinkableBoolean(true); // Add Time Slider Tool option tools menu
		
		public const enablePanelCoordsPercentageMode:LinkableBoolean = new LinkableBoolean(true); // resize/position tools when window gets resized (percentage based rather than absolute)
		public const enableToolAttributeEditing:LinkableBoolean = new LinkableBoolean(true); // edit the bindings of tool vis attributes
		public const showVisToolCloseDialog:LinkableBoolean = new LinkableBoolean(false); // show "close this window?" yes/no box
		public const enableToolSelection:LinkableBoolean = new LinkableBoolean(true); // enable/disable the selection tool
		public const enableToolProbe:LinkableBoolean = new LinkableBoolean(true);
		public const enableRightClick:LinkableBoolean = new LinkableBoolean(true);
		
		public const enableProbeAnimation:LinkableBoolean = new LinkableBoolean(true);
		public const maxTooltipRecordsShown:LinkableNumber = new LinkableNumber(1, verifyMaxTooltipRecordsShown); // maximum number of records shown in the probe toolTips
		public const enableBitmapFilters:LinkableBoolean = new LinkableBoolean(true); // enable/disable bitmap filters while probing or selecting
		public const enableGeometryProbing:LinkableBoolean = new LinkableBoolean(true); // use the geometry probing (default to on even though it may be slow for mapping)
		public const enableSessionMenu:LinkableBoolean = new LinkableBoolean(true); // all sessioning
		public const enableSessionBookmarks:LinkableBoolean = new LinkableBoolean(true);
		public const enableSessionEdit:LinkableBoolean = new LinkableBoolean(true);

		public const enableUserPreferences:LinkableBoolean = new LinkableBoolean(true); // open the User Preferences Panel
		
		public const enableSearchForRecord:LinkableBoolean = new LinkableBoolean(true); // allow user to right click search for record
		
		public const enableMarker:LinkableBoolean = new LinkableBoolean(true);
		public const enableDrawCircle:LinkableBoolean = new LinkableBoolean(true);
		
		public const enableMenuBar:LinkableBoolean = new LinkableBoolean(true); // top menu for advanced features
		public const enableTaskbar:LinkableBoolean = new LinkableBoolean(true); // taskbar for minimize/restore
		public const enableSubsetControls:LinkableBoolean = new LinkableBoolean(true); // creating subsets
		public const enableExportToolImage:LinkableBoolean = new LinkableBoolean(true); // print/export tool images
		public const enableExportApplicationScreenshot:LinkableBoolean = new LinkableBoolean(true); // print/export application screenshot
		public const enableExportDataTable:LinkableBoolean = new LinkableBoolean(true); // print/export data table
		
		public const enableDataMenu:LinkableBoolean = new LinkableBoolean(true); // enable/disable Data Menu
		public const enableRefreshHierarchies:LinkableBoolean = new LinkableBoolean(true);
		public const enableNewDataset:LinkableBoolean = new LinkableBoolean(true); // enable/disable New Dataset option
		public const enableAddWeaveDataSource:LinkableBoolean = new LinkableBoolean(true); // enable/disable Add WeaveDataSource option
		
		public const enableWindowMenu:LinkableBoolean = new LinkableBoolean(true); // enable/disable Window Menu
		public const enableGoFullscreen:LinkableBoolean = new LinkableBoolean(true); // enable/disable Fullscreen
		public const enableCloseAllWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Close All Windows
		public const enableRestoreAllMinimizedWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Restore All Minimized Windows 
		public const enableMinimizeAllWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Minimize All Windows
		public const enableCascadeAllWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Cascade All Windows
		public const enableTileAllWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Tile All Windows
		
		public const enableSelectionsMenu:LinkableBoolean = new LinkableBoolean(true);// enable/disable Selections Menu
		public const enableSaveCurrentSelection:LinkableBoolean = new LinkableBoolean(true);// enable/disable Save Current Selection option
		public const enableClearCurrentSelection:LinkableBoolean = new LinkableBoolean(true);// enable/disable Clear Current Selection option
		public const enableManageSavedSelections:LinkableBoolean = new LinkableBoolean(true);// enable/disable Manage Saved Selections option
		public const enableSelectionSelectorBox:LinkableBoolean = new LinkableBoolean(true); //enable/disable SelectionSelector option
		
		public const enableSubsetsMenu:LinkableBoolean = new LinkableBoolean(true);// enable/disable Subsets Menu
		public const enableCreateSubsets:LinkableBoolean = new LinkableBoolean(true);// enable/disable Create subset from selected records option
		public const enableRemoveSubsets:LinkableBoolean = new LinkableBoolean(true);// enable/disable Remove selected records from subset option
		public const enableShowAllRecords:LinkableBoolean = new LinkableBoolean(true);// enable/disable Show All Records option
		public const enableSaveCurrentSubset:LinkableBoolean = new LinkableBoolean(true);// enable/disable Save current subset option
		public const enableManageSavedSubsets:LinkableBoolean = new LinkableBoolean(true);// enable/disable Manage saved subsets option
		public const enableSubsetSelectionBox:LinkableBoolean = new LinkableBoolean(true);// enable/disable Subset Selection Combo Box option
		public const enableAddDataSource:LinkableBoolean = new LinkableBoolean(true);// enable/disable Manage saved subsets option
		public const enableEditDataSource:LinkableBoolean = new LinkableBoolean(true);
		
		public const dashboardMode:LinkableBoolean = new LinkableBoolean(false);	 // enable/disable borders/titleBar on windows
		public const enableToolControls:LinkableBoolean = new LinkableBoolean(true); // enable tool controls (which enables attribute selector too)
		
		public const enableFullscreen:LinkableBoolean = new LinkableBoolean(true); // enable/disable going fullscreen from Window menu
		
		public const enableAboutMenu:LinkableBoolean = new LinkableBoolean(true); //enable/disable About Menu
		
		public function get enableDebugAlert():LinkableBoolean { return DebugUtils.enableDebugAlert; } // show debug_trace strings in alert boxes
		public const showKeyTypeInColumnTitle:LinkableBoolean = new LinkableBoolean(false);
		
		// cosmetic options
		public const pageTitle:LinkableString = new LinkableString("Open Indicators Weave"); // title to show in browser window
		public const showCopyright:LinkableBoolean = new LinkableBoolean(true); // copyright at bottom of page

		// probing and selection
		public const selectionBlurringAmount:LinkableNumber = new LinkableNumber(4);
		public const selectionAlphaAmount:LinkableNumber    = new LinkableNumber(0.5, verifyAlpha);
		
		/**
		 * This is an array of LinkableEventListeners which specify a function to run on an event.
		 */
		public const eventListeners:LinkableHashMap = new LinkableHashMap(LinkableEventListener);
		
		/**
		 * Parameters for the DashedLine selection box.
		 * @default "5,5"
		 */
		public const dashedSelectionBox:LinkableString = new LinkableString("5,5", verifyDashedSelectionBox);
		public function verifyDashedSelectionBox(csv:String):Boolean
		{
			if (csv === null) 
				return false;
			
			var parser:CSVParser = new CSVParser();
			var rows:Array = parser.parseCSV(csv);
			
			if (rows.length == 0)
				return false;
			
			// Only the first row will be used
			var values:Array = rows[0];
			var foundNonZero:Boolean = false;
			for (var i:int = 0; i < values.length; ++i)
			{
				// We want every value >= 0 with at least one value > 0 
				// Undefined and negative numbers are invalid.
				var value:int = int(values[i]);
				if (isNaN(value)) 
					return false;
				if (value < 0) 
					return false;
				if (value != 0)
					foundNonZero = true; 
			}
			
			return foundNonZero;
		}
		
		public const panelTitleFontColor:LinkableNumber = new LinkableNumber(0xffffff, isFinite);
		public const panelTitleFontSize:LinkableNumber = new LinkableNumber(10, verifyFontSize);
		public const panelTitleFontFamily:LinkableString = new LinkableString("Verdana");
		public const panelTitleFontBold:LinkableBoolean = new LinkableBoolean(false);
		public const panelTitleFontItalic:LinkableBoolean = new LinkableBoolean(false);
		public const panelTitleFontUnderline:LinkableBoolean = new LinkableBoolean(false);
				
		public const axisFontColor:LinkableNumber = new LinkableNumber(0x000000, isFinite);
		public const axisFontSize:LinkableNumber = new LinkableNumber(DEFAULT_AXIS_FONT_SIZE, verifyFontSize);
		public const axisFontFamily:LinkableString = new LinkableString(DEFAULT_FONT_FAMILY);
		public const axisFontBold:LinkableBoolean = new LinkableBoolean(true);
		public const axisFontItalic:LinkableBoolean = new LinkableBoolean(false);
		public const axisFontUnderline:LinkableBoolean = new LinkableBoolean(false);
		
		public const probeInnerGlowColor:LinkableNumber = new LinkableNumber(0xffffff, isFinite);
		public const probeInnerGlowAlpha:LinkableNumber = new LinkableNumber(1, verifyAlpha);
		public const probeInnerGlowBlur:LinkableNumber = new LinkableNumber(5);
		public const probeInnerGlowStrength:LinkableNumber = new LinkableNumber(10);
		
		public const probeOuterGlowColor:LinkableNumber    = new LinkableNumber(0, isFinite);
		public const probeOuterGlowAlpha:LinkableNumber    = new LinkableNumber(1, verifyAlpha);
		public const probeOuterGlowBlur:LinkableNumber 	   = new LinkableNumber(3);
		public const probeOuterGlowStrength:LinkableNumber = new LinkableNumber(3);
		
		public const shadowDistance:LinkableNumber  = new LinkableNumber(2);
		public const shadowAngle:LinkableNumber    	= new LinkableNumber(45);
		public const shadowColor:LinkableNumber 	= new LinkableNumber(0x000000, isFinite);
		public const shadowAlpha:LinkableNumber 	= new LinkableNumber(0.5, verifyAlpha);
		public const shadowBlur:LinkableNumber 		= new LinkableNumber(4);
		
		public const probeToolTipBackgroundAlpha:LinkableNumber = new LinkableNumber(1.0, verifyAlpha);
		public const probeToolTipBackgroundColor:LinkableNumber = new LinkableNumber(NaN);
		public const probeToolTipFontColor:LinkableNumber = new LinkableNumber(0x000000, isFinite);
		
		public const enableProbeLines:LinkableBoolean = new LinkableBoolean(true);

		public const toolInteractions:InteractionController = new InteractionController();
		
		// temporary?
		public const rServiceURL:LinkableString = registerLinkableChild(this, new LinkableString("/WeaveServices/RService"), handleRServiceURLChange);// url of Weave R service using Rserve
		public const jriServiceURL:LinkableString = new LinkableString("/WeaveServices/JRIService");// url of Weave R service using JRI
		public const pdbServiceURL:LinkableString = new LinkableString("/WeavePDBService/PDBService");
		
		private function handleRServiceURLChange():void
		{
			rServiceURL.value = rServiceURL.value.replace('OpenIndicatorsRServices', 'WeaveServices');
			if (rServiceURL.value == '/WeaveServices')
				rServiceURL.value += '/RService';
		}
		
		//default URL
		public const searchServiceURLs:LinkableString = new LinkableString([WIKIPEDIA_URL, GOOGLE_URL, GOOGLE_IMAGES_URL, GOOGLE_MAPS_URL].join('\n'));
		
		// when this is true, a rectangle will be drawn around the screen bounds with the background
		public const debugScreenBounds:LinkableBoolean = new LinkableBoolean(false);

		
		/**
		 * This field contains JavaScript code that will run when Weave is loaded, immediately after the session state
		 * interface is initialized.  The variable 'weave' can be used in the JavaScript code to refer to the weave instance.
		 */
		public const startupJavaScript:LinkableString = new LinkableString();
		
		/**
		 * This function will run the JavaScript code specified in the startupScript LinkableString.
		 */
		public function runStartupJavaScript():void
		{
			if (!startupJavaScript.value)
				return;
			
			var script:String = 'function(id){ var weave = document.getElementById(id); ' + startupJavaScript.value + ' }';
			var prev:Boolean = ExternalInterface.marshallExceptions;
			try
			{
				ExternalInterface.marshallExceptions = true;
				ExternalInterface.call(script, ExternalInterface.objectID);
			}
			catch (e:Error)
			{
				reportError(e);
			}
			finally
			{
				ExternalInterface.marshallExceptions = prev;
			}
		}
		
		/**
		 * @see weave.core.LinkableFunction#macros
		 */
		public function get macros():ILinkableHashMap { return LinkableFunction.macros; }
		/**
		 * @see weave.core.LinkableFunction#macroLibraries
		 */
		public function get macroLibraries():LinkableString { return LinkableFunction.macroLibraries; }
		/**
		 * @see weave.core.LinkableFunction#includeMacroLibrary
		 */
		public function includeMacroLibrary(libraryName:String):void
		{
			LinkableFunction.includeMacroLibrary(libraryName);
		}
		
		public const workspaceWidth:LinkableNumber = new LinkableNumber(NaN);
		public const workspaceHeight:LinkableNumber = new LinkableNumber(NaN);


		//--------------------------------------------
		// BACKWARDS COMPATIBILITY
		[Deprecated(replacement="panelTitleFontFamily")] public function set panelTitleFontStyle(value:String):void
		{
			panelTitleFontFamily.value = value;
		}
		[Deprecated(replacement="dashboardMode")] public function set enableToolBorders(value:Boolean):void
		{
			dashboardMode.value = !value;
		}
		[Deprecated(replacement="dashboardMode")] public function set enableBorders(value:Boolean):void
		{
			dashboardMode.value = !value;
		}
		[Deprecated(replacement="enableSessionBookmarks")] public function set enableSavePoint(value:Boolean):void
		{
			enableSessionBookmarks.value = value;
		}
		[Deprecated(replacement="showProbeToolTipEditor")] public function set showProbeColumnEditor(value:Boolean):void
		{
			showProbeToolTipEditor.value = value;
		}
		[Deprecated(replacement="enableAddWeaveDataSource")] public function set enableAddOpenIndicatorsDataSource(value:Boolean):void
		{
			enableAddWeaveDataSource.value = value;
		}
		[Deprecated(replacement="enablePanelCoordsPercentageMode")] public function set enableToolAutoResizeAndPosition(value:Boolean):void
		{
			enablePanelCoordsPercentageMode.value = value;
		}
		[Deprecated(replacement="rServiceURL")] public function set rServicesURL(value:String):void
		{
			if (value != '/OpenIndicatorsRServices')
				rServiceURL.value = value + '/RService';
		}
		//--------------------------------------------
	}
}
