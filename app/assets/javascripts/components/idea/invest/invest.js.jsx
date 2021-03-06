var Invest = React.createClass({

  getInitialState: function() {
    return {
      idea: this.props.idea,
      mode: false,
      amount: 0,
      loading: false
    }
  },

  componentDidMount: function() {
    $('body textarea').on('focus', function(){
      $(this).autosize();
    });
  },

  sendInvestment: function(formData, action, amount) {
    this.setState({amount: amount.amount});
    this.setState({loading: true});
    $.ajaxSetup({ cache: false });
    $.ajax({
      data: formData,
      url: action,
      type: "POST",
      dataType: "json",
      success: function ( data ) {
        if(!data.error) {
          this.setState({idea: data.idea});
          this.setState({mode: false});
          this.setState({loading: false});
          $("#investPopup").modal('hide');
          $.pubsub('publish', 'idea_invested', true);
          $.pubsub('publish', 'update_investment_stats', data.idea.amount);
          $('body textarea').trigger('autosize.destroy');
          $('body').pgNotification({style: "simple", message: "<span>You have successfully invested "+data.idea.amount+ " coins into " + data.idea.name +"</span>", position: "bottom-left", type: "success",timeout: 5000}).show();
        }
      }.bind(this),
      error: function(xhr, status, err) {
        $("#investPopup").modal('hide');
        $('body').pgNotification({style: "simple", message: JSON.parse(xhr.responseText).error.toString(), position: "top-right", type: "danger",timeout: 5000}).show();
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  },

  render: function() {
    if(this.state.idea.can_invest) {
      if(this.state.idea.investable) {
        var content =   <div className="modal-body">
                          <InvestForm loading= {this.state.loading} form={this.state.idea.form} sendInvestment= {this.sendInvestment} idea={this.state.idea} />
                        </div>;
      } else {
        var content = <div className="modal-body">
                        <NotInvestable idea={this.state.idea} />
                      </div>
      }
    } else {
      var content = <NoBalance />;
    }

    return (
      <div className="investapp invest-box">
        <div className="modal fade stick-up" tabIndex="-1" role="dialog" id="investPopup" aria-labelledby="investlPopupLabel" aria-hidden="true" data-backdrop="static" data-keyboard="false">
          <div className="modal-dialog modal-md">
          <div className="modal-content-wrapper">
            <div className="modal-content">
               <div className="modal-header clearfix text-left">
                  <button type="button" className="close" data-dismiss="modal" aria-hidden="true">
                    <i className="pg-close fs-14"></i>
                  </button>
                  <h5 className="b-b b-grey p-b-5 pull-left">Invest into <span className="semi-bold">{this.state.idea.name}</span></h5>
              </div>
              {content}
          </div>
          </div>
          </div>
        </div>
      </div>
    )
  }
});
