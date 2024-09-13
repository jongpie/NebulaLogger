//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//


public without sharing class LoggerFinalizerContext {
  public System.FinalizerContext finalizerContext;

  public LoggerFinalizerContext(System.FinalizerContext finalizerContext) {
    this.finalizerContext = finalizerContext;
  }
}
