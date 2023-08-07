package de.quester.tapetool8;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;

import de.quester.tapetool8.CTap.ZXTapeEntry;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;

public class CDialogTape extends Dialog {

	protected Object result;
	protected Shell shell;
	private Table table;
	CTap mTap;

	/**
	 * Create the dialog.
	 * @param parent
	 * @param style
	 */
	public CDialogTape(Shell parent, int style) {
		super(parent, style);
		setText("SWT Dialog");
	}

	/**
	 * Open the dialog.
	 * @return the result
	 */
	public Object open() {
		createContents();
		shell.open();
		shell.layout();
		Display display = getParent().getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		return result;
	}

	/**
	 * Create contents of the dialog.
	 */
	private void createContents() {
		shell = new Shell(getParent(), getStyle());
		shell.setSize(745, 584);
		shell.setText(getText());
		
		table = new Table(shell, SWT.BORDER | SWT.FULL_SELECTION);
		table.setBounds(0, 0, 724, 488);
		table.setHeaderVisible(true);
		table.setLinesVisible(true);
		
		Composite composite = new Composite(shell, SWT.NONE);
		composite.setBounds(0, 494, 724, 52);
		
		Button btnOpen = new Button(composite, SWT.NONE);
		btnOpen.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				onOpen();
			}
		});
		btnOpen.setBounds(639, 10, 75, 25);
		btnOpen.setText("Open");

	}

	protected void onOpen() {
		mTap = new CTap();
		mTap.loadTape("D:\\Emulator\\z80\\dev\\chip8\\testtape.tap");
		updateList();
		
	}

	private void updateList() {
		TableColumn col = new TableColumn(table, SWT.NONE);
		col.setText("Name");
		col = new TableColumn(table, SWT.NONE);
		col.setText("Typ");
		col = new TableColumn(table, SWT.NONE);
		col.setText("Par1");
		col = new TableColumn(table, SWT.NONE);
		col.setText("Par2");
		for (ZXTapeEntry entry: mTap.entries) {
			TableItem item = new TableItem(table,SWT.NONE);
			item.setText(0, entry.name);
			item.setText(1, entry.typName());
			item.setText(2, String.format("%d",  entry.par1()));
			item.setText(3, String.format("%d",  entry.par2()));
		}
		for (int i=0;i<4;i++) table.getColumn(i).pack();

	}
}
