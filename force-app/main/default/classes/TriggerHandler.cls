/**
 * @description Abstract base class for trigger handlers.
 * Provides a structured framework for handling trigger events
 * with built-in recursion prevention.
 *
 * Usage: Create a handler class extending TriggerHandler,
 * override the relevant methods, and call run() from the trigger.
 *
 * Example:
 *   trigger MyTrigger on MyObject__c (before insert, after update) {
 *       new MyTriggerHandler().run();
 *   }
 */
public abstract class TriggerHandler {

    private static Set<String> bypassedHandlers = new Set<String>();

    @TestVisible
    private TriggerContext context;

    public TriggerHandler() {
        this.setTriggerContext();
    }

    /**
     * @description Main entry point. Dispatches to the appropriate handler method
     * based on the current trigger context.
     */
    public void run() {
        if (isBypassed()) {
            return;
        }

        switch on this.context {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when BEFORE_UPDATE {
                this.beforeUpdate();
            }
            when BEFORE_DELETE {
                this.beforeDelete();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }
    }

    // --- Bypass management ---

    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }

    private Boolean isBypassed() {
        return bypassedHandlers.contains(getHandlerName());
    }

    @TestVisible
    private String getHandlerName() {
        return String.valueOf(this).split(':')[0];
    }

    // --- Virtual methods to override ---

    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void beforeInsert() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void beforeUpdate() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void beforeDelete() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void afterInsert() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void afterUpdate() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void afterDelete() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void afterUndelete() {}

    // --- Private helpers ---

    private void setTriggerContext() {
        if (Trigger.isExecuting && Trigger.operationType != null) {
            switch on Trigger.operationType {
                when BEFORE_INSERT  { this.context = TriggerContext.BEFORE_INSERT; }
                when BEFORE_UPDATE  { this.context = TriggerContext.BEFORE_UPDATE; }
                when BEFORE_DELETE  { this.context = TriggerContext.BEFORE_DELETE; }
                when AFTER_INSERT   { this.context = TriggerContext.AFTER_INSERT; }
                when AFTER_UPDATE   { this.context = TriggerContext.AFTER_UPDATE; }
                when AFTER_DELETE   { this.context = TriggerContext.AFTER_DELETE; }
                when AFTER_UNDELETE { this.context = TriggerContext.AFTER_UNDELETE; }
            }
        }
    }

    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT,
        BEFORE_UPDATE,
        BEFORE_DELETE,
        AFTER_INSERT,
        AFTER_UPDATE,
        AFTER_DELETE,
        AFTER_UNDELETE
    }
}
