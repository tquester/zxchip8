package de.quester.tapetool8;

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;

public class MainClass {

	public static void main(String[] args) {
		System.out.println("ZX Chip8 Tape Tool");
		String inputFile;
		String outputFile;
		CParameter parameters = new CParameter(args);
		
		if (parameters.isCmd("intro")) {
			 inputFile = parameters.getParam("input");
			 outputFile = parameters.getParam("output");
			 String gamefile = parameters.getParam("game");
			 CUpdateIntro updateIntro = new CUpdateIntro();
			 updateIntro.updateIntro(inputFile, gamefile, outputFile);
			 return;
		}
		
		
		
        Display display = new Display();
        Shell shell = new Shell(display);
        shell.setText("Hallo Welt");
        shell.setLayout(new FillLayout(SWT.VERTICAL));
        CDialogTape mainDialog = new CDialogTape(shell, SWT.TITLE + SWT.MAX + SWT.RESIZE + SWT.CLOSE);
        mainDialog.open();
	}

}
