//------------------------------------------------------------------------------------------------//
// Prototype 2 — small helper around Apex's StubProvider that turns the bare-bones
// handleMethodCall() callback into a fluent .when('method').thenReturn(value) builder. This is
// the part that makes tests in Prototype 2 readable; without it, raw StubProvider tests would
// be even more verbose than Prototype 1.
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.AvoidGlobalModifier')
@IsTest
public class LoggerStubHandler implements System.StubProvider {
  private final Map<String, Object> returnValuesByMethodName = new Map<String, Object>();
  private final Map<String, Integer> callCountsByMethodName = new Map<String, Integer>();

  /**
   * @description Register a return value for the given method name. Subsequent calls to that
   *              method on the stubbed object will return this value.
   */
  public LoggerStubHandler whenCalled(String methodName, Object returnValue) {
    this.returnValuesByMethodName.put(methodName, returnValue);
    return this;
  }

  /**
   * @description Returns how many times the given method was invoked on the stubbed object.
   *              Useful for `assert it never called X` and `assert it called Y exactly once`.
   */
  public Integer callCountFor(String methodName) {
    return this.callCountsByMethodName.containsKey(methodName) ? this.callCountsByMethodName.get(methodName) : 0;
  }

  public Object handleMethodCall(
    Object stubbedObject,
    String stubbedMethodName,
    System.Type returnType,
    List<System.Type> paramTypes,
    List<String> paramNames,
    List<Object> args
  ) {
    Integer prior = this.callCountsByMethodName.containsKey(stubbedMethodName) ? this.callCountsByMethodName.get(stubbedMethodName) : 0;
    this.callCountsByMethodName.put(stubbedMethodName, prior + 1);

    if (this.returnValuesByMethodName.containsKey(stubbedMethodName)) {
      return this.returnValuesByMethodName.get(stubbedMethodName);
    }

    // Default for un-stubbed methods: return null (Apex StubProvider conventions). Tests that
    // care can `System.Assert.areEqual(0, handler.callCountFor('someMethodName'))` to detect
    // unintended fall-through.
    return null;
  }
}
