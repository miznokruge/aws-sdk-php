<?php
namespace Aws\Common\Api\Serializer;

use Aws\Common\Api\StructureShape;
use Aws\Common\Api\Service;
use GuzzleHttp\Message\RequestInterface;
use GuzzleHttp\Stream;

/**
 * @internal
 */
class RestXmlSerializer extends RestSerializer
{
    /** @var XmlBody */
    private $xmlBody;

    protected $contentType = 'application/xml';

    /**
     * @param Service $api      Service API description
     * @param string  $endpoint Endpoint to connect to
     * @param XmlBody $xmlBody  Optional XML formatter to use
     */
    public function __construct(
        Service $api,
        $endpoint,
        XmlBody $xmlBody = null
    ) {
        parent::__construct($api, $endpoint);
        $this->xmlBody = $xmlBody ?: new XmlBody($api);
    }

    protected function payload(
        RequestInterface $request,
        StructureShape $member,
        array $value
    ) {
        $request->setBody(Stream\create(
            $this->xmlBody->build($member, $value)
        ));
    }
}