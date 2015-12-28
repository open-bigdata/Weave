/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weavejs.core
{
	import weavejs.WeaveAPI;
	import weavejs.util.JS;
	
	/**
	 * This is an interface for reading and writing data in the Weave file format.
	 * 
	 * @author adufilie
	 */
	public class WeaveArchive
	{
		/**
		 * @param input A Weave file to decode.
		 */
		public function WeaveArchive(bytes:* = null)
		{
			if (bytes)
				_readArchive(bytes);
		}
		
		/**
		 * This is a dynamic object containing all the files (ByteArray objects) in the archive.
		 * The property names used in this object must be valid filenames or serialize() will fail.
		 */
		public const files:Object = {};
		
		/**
		 * This is a dynamic object containing all the amf objects stored in the archive.
		 * The property names used in this object must be valid filenames or serialize() will fail.
		 */
		public const objects:Object = {};
		
		private static const FOLDER_AMF:String = "weave-amf"; // folder used for amf-encoded objects
		private static const FOLDER_JSON:String = "weave-json"; // folder used for JSON-encoded objects
		private static const FOLDER_FILES:String = "weave-files"; // folder used for raw files
		
		/**
		 * @private
		 */		
		private function _readArchive(bytes:*):void
		{
			var JSZip:Class = JS.global.JSZip;
			var zip:Object = new JSZip(bytes);
			for (var filePath:String in zip.files)
			{
				var fileName:String = filePath.substr(filePath.indexOf('/') + 1);
				var file:Object = zip.files[filePath];
				if (filePath.indexOf(FOLDER_JSON + '/') == 0)
				{
					objects[fileName] = JSON.parse(file.asText());
				}
				else if (filePath.indexOf(FOLDER_AMF + '/') == 0)
				{
					var ByteArray:Class = JS.global.a3d.ByteArray;
					var bytes:Object = new ByteArray(file.asBinary());
					objects[fileName] = bytes.readObject();
				}
				else
				{
					files[fileName] = file.asBinary();
				}
			}
		}
		
		/**
		 * This function will create a ByteArray containing the objects that have been specified with setObject().
		 * @param contentType A String describing the type of content contained in the objects.
		 * @return A ByteArray in the Weave file format.
		 */
		public function serialize():*
		{
			var JSZip:Class = JS.global.JSZip;
			var zip:Object = new JSZip();
			var name:String;
			var folder:Object;
			
			folder = zip.folder(FOLDER_FILES);
			for (name in files)
				folder.file(name, files[name]);
			
			folder = zip.folder(FOLDER_JSON);
			for (name in objects)
				folder.file(name, JSON.stringify(objects[name]));
			
			return zip.generate({type: 'blob'});
		}
		
		public static const HISTORY_SYNC_DELAY:int = 100;
		public static const THUMBNAIL_SIZE:int = 200;
		public static const ARCHIVE_THUMBNAIL_PNG:String = "thumbnail.png";
		public static const ARCHIVE_SCREENSHOT_PNG:String = "screenshot.png";
		public static const ARCHIVE_PLUGINS_AMF:String = "plugins.amf";
		public static const ARCHIVE_HISTORY_AMF:String = "history.amf";
		public static const ARCHIVE_URL_CACHE_AMF:String = "url-cache.amf";
		public static const ARCHIVE_COLUMN_CACHE_AMF:String = "column-cache.amf";
		
		/**
		 * This function will create an object that can be saved to a file and recalled later with loadWeaveFileContent().
		 */
		public static function createWeaveFileContent(weave:Weave, saveScreenshot:Boolean=false, pluginList:Array = null):*
		{
			var output:WeaveArchive = new WeaveArchive();
			
			// thumbnail should go first in the stream because we will often just want to extract the thumbnail and nothing else.
//			updateLocalThumbnailAndScreenshot(saveScreenshot);
			
			// embedded files
//			for each (var fileName:String in WeaveAPI.URLRequestUtils.getLocalFileNames())
//				output.files[fileName] = WeaveAPI.URLRequestUtils.getLocalFile(fileName);
			
			// for forwards compatibility, don't include plugin list unless it has items
//			if (pluginList && pluginList.length)
//				output.objects[ARCHIVE_PLUGINS_AMF] = pluginList;
			
			// session history
			var _history:Object = weave.history.getSessionState();
			output.objects[ARCHIVE_HISTORY_AMF] = _history;
			
			// TEMPORARY SOLUTION - url cache
//			if (WeaveAPI.URLRequestUtils['saveCache'])
//				output.objects[ARCHIVE_URL_CACHE_AMF] = WeaveAPI.URLRequestUtils.getCache();
			
			// TEMPORARY SOLUTION - column cache
			if (WeaveAPI.AttributeColumnCache['saveCache'])
				output.objects[ARCHIVE_COLUMN_CACHE_AMF] = WeaveAPI.AttributeColumnCache['saveCache'];
			
			return output.serialize();
		}
	}
}
