/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.ui
{
	import weave.api.core.ILinkableObject;

	/**
	 * Manages implementations of ILinkableObjectEditor.
	 */
	public interface IEditorManager
	{
		/**
		 * This function will register an ILinkableObjectEditor Class corresponding to an ILinkableObject Class.
		 * @param objType A Class that implements ILinkableObject
		 * @param editorType The corresponding Class implementing ILinkableObjectEditor
		 */
		function registerEditor(objType:Class, editorType:Class):void;
		
		/**
		 * Gets the class that was previously registered for 
		 * @param linkableObjectOrClass An object or Class implementing ILinkableObject.
		 * @return The Class implementing ILinkableObjectEditor that was previously registered for the given type of object or one of its superclasses.
		 */
		function getEditorClass(linkableObjectOrClass:Object):Class;
		
		/**
		 * Creates a new editor for an ILinkableObject.
		 * @param obj An ILinkableObject.
		 * @return A new editor for the object, or null if there is no registered editor class.
		 */
		function getNewEditor(obj:ILinkableObject):ILinkableObjectEditor;
		
		/**
		 * Sets a human-readable label for an ILinkableObject to be used in editors.
		 */
		function setLabel(object:ILinkableObject, label:String):void;
		
		/**
		 * Gets the previously-stored human-readable label for an ILinkableObject.
		 */
		function getLabel(object:ILinkableObject):String;
	}
}
