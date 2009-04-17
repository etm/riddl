/**
 * 
 */
package org.riddl.handlers.xml;

import org.xml.sax.SAXParseException;

import com.sun.tools.xjc.AbortException;
import com.sun.tools.xjc.ErrorReceiver;

final class SysoutErrorReceiver extends ErrorReceiver {
	@Override
	public void warning(SAXParseException exception) throws AbortException {
		print("WARNING: " + exception.getLineNumber() + " - " + exception.getMessage());

	}

	@Override
	public void info(SAXParseException exception) {
		print("INFO: " + exception.getLineNumber() + " - " + exception.getMessage());

	}

	@Override
	public void fatalError(SAXParseException exception) throws AbortException {
		print("FATAL: " + exception.getLineNumber() + " - " + exception.getMessage());
		print(exception.getColumnNumber());

	}

	@Override
	public void error(SAXParseException exception) throws AbortException {
		print("ERROR: " + exception.getLineNumber() + " - " + exception.getMessage());

	}
	
	private void print(Object o)
	{
		System.out.println(o.toString());
	}
	
}